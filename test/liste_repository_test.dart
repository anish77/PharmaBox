import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_box/firebase/liste_repository.dart';

const uid = 'utente_test';

void main() {
  late FakeFirebaseFirestore db;
  late ListeRepository repo;

  Future<Map<String, dynamic>> lista(String id) async =>
      (await db.doc('users/$uid/liste/$id').get()).data() ?? {};

  Future<String> nuovaLista(String nome) async {
    final id = repo.creaLista(uid, nome);
    // creaLista non attende la scrittura
    await Future<void>.delayed(Duration.zero);
    return id;
  }

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = ListeRepository.conDb(db);
    await db.doc('users/$uid').set({'email': 'test@example.com'});
  });

  group('liste', () {
    test('creaLista e leggiListe in ordine di creazione', () async {
      final a = await nuovaLista('Prima');
      final b = await nuovaLista('Seconda');

      final liste = await repo.leggiListe(uid);
      expect(liste.map((l) => l.id), [a, b]);
      expect(liste.first.nome, 'Prima');
      expect(liste.first.totalePezzi, 0);
    });

    test('esisteNome ignora maiuscole/spazi e rispetta escludiId', () async {
      final id = await nuovaLista('Magazzino');

      expect(await repo.esisteNome(uid, '  magazzino '), isTrue);
      expect(await repo.esisteNome(uid, 'Altro'), isFalse);
      expect(await repo.esisteNome(uid, 'MAGAZZINO', escludiId: id), isFalse);
    });

    test('rinominaLista', () async {
      final id = await nuovaLista('Vecchio');
      await repo.rinominaLista(uid, id, 'Nuovo');
      expect((await lista(id))['nome'], 'Nuovo');
    });

    test('streamListe emette le liste', () async {
      await nuovaLista('Stream');
      final liste = await repo.streamListe(uid).first;
      expect(liste.map((l) => l.nome), ['Stream']);
    });

    test('eliminaLista cancella lista e prodotti', () async {
      final id = await nuovaLista('Da eliminare');
      await repo.incrementa(uid, id, minsan: '111', titolo: 'A', delta: 3);

      await repo.eliminaLista(uid, id);

      expect((await db.doc('users/$uid/liste/$id').get()).exists, isFalse);
      expect(await repo.leggiItems(uid, id), isEmpty);
    });
  });

  group('prodotti', () {
    late String id;
    setUp(() async => id = await nuovaLista('Inventario'));

    test('incrementa somma i pezzi e aggiorna il totale lista', () async {
      await repo.incrementa(uid, id, minsan: '111', titolo: 'Tachipirina');
      await repo.incrementa(uid, id, minsan: '111', titolo: 'Tachipirina');
      await repo.incrementa(uid, id, minsan: '222', titolo: 'Oki', delta: 5);

      final items = {for (final i in await repo.leggiItems(uid, id)) i.minsan: i};
      expect(items['111']!.quantity, 2);
      expect(items['111']!.titolo, 'Tachipirina');
      expect(items['222']!.quantity, 5);
      expect((await lista(id))['totalePezzi'], 7);
    });

    test('incrementi concorrenti non perdono pezzi', () async {
      await Future.wait([
        for (var i = 0; i < 20; i++)
          repo.incrementa(uid, id, minsan: '111', titolo: 'A'),
      ]);
      expect((await repo.leggiItems(uid, id)).single.quantity, 20);
      expect((await lista(id))['totalePezzi'], 20);
    });

    test('impostaQuantita a 0 lascia il prodotto in lista', () async {
      await repo.incrementa(uid, id, minsan: '111', titolo: 'A', delta: 4);

      await repo.impostaQuantita(
        uid,
        id,
        minsan: '111',
        titolo: 'A',
        quantity: 0,
        delta: -4,
      );

      final item = (await repo.leggiItems(uid, id)).single;
      expect(item.minsan, '111');
      expect(item.quantity, 0);
      expect((await lista(id))['totalePezzi'], 0);
    });

    test('impostaQuantita con valore esatto', () async {
      await repo.incrementa(uid, id, minsan: '111', titolo: 'A', delta: 2);
      await repo.impostaQuantita(
        uid,
        id,
        minsan: '111',
        titolo: 'A',
        quantity: 9,
        delta: 7,
      );
      expect((await repo.leggiItems(uid, id)).single.quantity, 9);
      expect((await lista(id))['totalePezzi'], 9);
    });

    test('rimuoviItem elimina il prodotto e scala il totale', () async {
      await repo.incrementa(uid, id, minsan: '111', titolo: 'A', delta: 3);
      await repo.incrementa(uid, id, minsan: '222', titolo: 'B', delta: 2);

      await repo.rimuoviItem(uid, id, minsan: '111', quantity: 3);

      expect((await repo.leggiItems(uid, id)).map((i) => i.minsan), ['222']);
      expect((await lista(id))['totalePezzi'], 2);
    });

    test('rimuoviItem di un prodotto a 0 pezzi', () async {
      await repo.incrementa(uid, id, minsan: '111', titolo: 'A', delta: 1);
      await repo.impostaQuantita(
        uid,
        id,
        minsan: '111',
        titolo: 'A',
        quantity: 0,
        delta: -1,
      );

      await repo.rimuoviItem(uid, id, minsan: '111', quantity: 0);

      expect(await repo.leggiItems(uid, id), isEmpty);
      expect((await lista(id))['totalePezzi'], 0);
    });

    test('svuotaLista toglie tutti i prodotti', () async {
      await repo.incrementa(uid, id, minsan: '111', titolo: 'A', delta: 3);
      await repo.incrementa(uid, id, minsan: '222', titolo: 'B', delta: 2);

      await repo.svuotaLista(uid, id);

      expect(await repo.leggiItems(uid, id), isEmpty);
      expect((await lista(id))['totalePezzi'], 0);
    });

    test('MINSAN con "/" è ammesso', () async {
      await repo.incrementa(uid, id, minsan: 'AB/12', titolo: 'A');
      final item = (await repo.leggiItems(uid, id)).single;
      expect(item.minsan, 'AB/12');
    });

    test('streamItems riflette le modifiche', () async {
      await repo.incrementa(uid, id, minsan: '111', titolo: 'A', delta: 2);
      final items = await repo.streamItems(uid, id).first;
      expect(items.single.quantity, 2);
    });
  });

  group('migrazione liste legacy', () {
    Future<void> legacy(List<Map<String, dynamic>> liste) =>
        db.doc('users/$uid').set({'liste': liste});

    test('copia liste e prodotti nelle sottocollezioni', () async {
      await legacy([
        {
          'nomeLista': 'Ottobre',
          'items': [
            {'minsan': '111', 'titolo': 'A', 'quantity': 2},
            {'minsan': '111', 'titolo': 'A', 'quantity': 1},
            {'minsan': '222', 'titolo': 'B', 'quantity': 0},
          ],
        },
        {
          'nomeLista': 'Vecchio formato',
          'prodotti': [
            {'id': '333', 'name': 'C', 'qty': '4'},
          ],
        },
        {'nomeLista': '', 'items': []},
      ]);

      await repo.migraListeLegacy(uid);

      final liste = await repo.leggiListe(uid);
      expect(liste.map((l) => l.nome), ['Ottobre', 'Vecchio formato']);
      expect(liste.map((l) => l.totalePezzi), [3, 4]);

      final ottobre = {
        for (final i in await repo.leggiItems(uid, liste[0].id)) i.minsan: i,
      };
      expect(ottobre['111']!.quantity, 3);
      // I prodotti a 0 pezzi restano in lista
      expect(ottobre['222']!.quantity, 0);

      final vecchio = (await repo.leggiItems(uid, liste[1].id)).single;
      expect(vecchio.minsan, '333');
      expect(vecchio.titolo, 'C');
      expect(vecchio.quantity, 4);

      final utente = (await db.doc('users/$uid').get()).data()!;
      expect(utente['listeMigrate'], isTrue);
      expect(utente['liste'], hasLength(3), reason: 'array lasciato come backup');
    });

    test('rieseguita non duplica le liste', () async {
      await legacy([
        {
          'nomeLista': 'Unica',
          'items': [
            {'minsan': '111', 'titolo': 'A', 'quantity': 1},
          ],
        },
      ]);

      await repo.migraListeLegacy(uid);
      // Simula una migrazione interrotta prima del flag
      await db.doc('users/$uid').update({'listeMigrate': FieldValue.delete()});
      await repo.migraListeLegacy(uid);

      final liste = await repo.leggiListe(uid);
      expect(liste, hasLength(1));
      expect(liste.single.totalePezzi, 1);
    });

    test('non fa nulla se già migrate', () async {
      await legacy([
        {'nomeLista': 'X', 'items': []},
      ]);
      await db.doc('users/$uid').update({'listeMigrate': true});

      await repo.migraListeLegacy(uid);

      expect(await repo.leggiListe(uid), isEmpty);
    });
  });
}
