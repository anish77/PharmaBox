// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prodotto_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProdottoIsarCollection on Isar {
  IsarCollection<ProdottoIsar> get prodottoIsars => this.collection();
}

const ProdottoIsarSchema = CollectionSchema(
  name: r'ProdottoIsar',
  id: 5580715755831361598,
  properties: {
    r'codice': PropertySchema(
      id: 0,
      name: r'codice',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'howToTake': PropertySchema(
      id: 2,
      name: r'howToTake',
      type: IsarType.string,
    ),
    r'immagine': PropertySchema(
      id: 3,
      name: r'immagine',
      type: IsarType.string,
    ),
    r'ingredients': PropertySchema(
      id: 4,
      name: r'ingredients',
      type: IsarType.string,
    ),
    r'minsan': PropertySchema(
      id: 5,
      name: r'minsan',
      type: IsarType.string,
    ),
    r'nome': PropertySchema(
      id: 6,
      name: r'nome',
      type: IsarType.string,
    ),
    r'pezzi': PropertySchema(
      id: 7,
      name: r'pezzi',
      type: IsarType.long,
    ),
    r'rendibile': PropertySchema(
      id: 8,
      name: r'rendibile',
      type: IsarType.stringList,
    ),
    r'tipoProdotto': PropertySchema(
      id: 9,
      name: r'tipoProdotto',
      type: IsarType.string,
    ),
    r'tipoProdottoDettaglio': PropertySchema(
      id: 10,
      name: r'tipoProdottoDettaglio',
      type: IsarType.string,
    ),
    r'vendibile': PropertySchema(
      id: 11,
      name: r'vendibile',
      type: IsarType.long,
    )
  },
  estimateSize: _prodottoIsarEstimateSize,
  serialize: _prodottoIsarSerialize,
  deserialize: _prodottoIsarDeserialize,
  deserializeProp: _prodottoIsarDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _prodottoIsarGetId,
  getLinks: _prodottoIsarGetLinks,
  attach: _prodottoIsarAttach,
  version: '3.1.0+1',
);

int _prodottoIsarEstimateSize(
  ProdottoIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.codice.length * 3;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.howToTake.length * 3;
  bytesCount += 3 + object.immagine.length * 3;
  bytesCount += 3 + object.ingredients.length * 3;
  bytesCount += 3 + object.minsan.length * 3;
  bytesCount += 3 + object.nome.length * 3;
  bytesCount += 3 + object.rendibile.length * 3;
  {
    for (var i = 0; i < object.rendibile.length; i++) {
      final value = object.rendibile[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.tipoProdotto;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.tipoProdottoDettaglio;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _prodottoIsarSerialize(
  ProdottoIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.codice);
  writer.writeString(offsets[1], object.description);
  writer.writeString(offsets[2], object.howToTake);
  writer.writeString(offsets[3], object.immagine);
  writer.writeString(offsets[4], object.ingredients);
  writer.writeString(offsets[5], object.minsan);
  writer.writeString(offsets[6], object.nome);
  writer.writeLong(offsets[7], object.pezzi);
  writer.writeStringList(offsets[8], object.rendibile);
  writer.writeString(offsets[9], object.tipoProdotto);
  writer.writeString(offsets[10], object.tipoProdottoDettaglio);
  writer.writeLong(offsets[11], object.vendibile);
}

ProdottoIsar _prodottoIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProdottoIsar();
  object.codice = reader.readString(offsets[0]);
  object.description = reader.readString(offsets[1]);
  object.howToTake = reader.readString(offsets[2]);
  object.id = id;
  object.immagine = reader.readString(offsets[3]);
  object.ingredients = reader.readString(offsets[4]);
  object.minsan = reader.readString(offsets[5]);
  object.nome = reader.readString(offsets[6]);
  object.pezzi = reader.readLong(offsets[7]);
  object.rendibile = reader.readStringList(offsets[8]) ?? [];
  object.tipoProdotto = reader.readStringOrNull(offsets[9]);
  object.tipoProdottoDettaglio = reader.readStringOrNull(offsets[10]);
  object.vendibile = reader.readLong(offsets[11]);
  return object;
}

P _prodottoIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readStringList(offset) ?? []) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _prodottoIsarGetId(ProdottoIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _prodottoIsarGetLinks(ProdottoIsar object) {
  return [];
}

void _prodottoIsarAttach(
    IsarCollection<dynamic> col, Id id, ProdottoIsar object) {
  object.id = id;
}

extension ProdottoIsarQueryWhereSort
    on QueryBuilder<ProdottoIsar, ProdottoIsar, QWhere> {
  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProdottoIsarQueryWhere
    on QueryBuilder<ProdottoIsar, ProdottoIsar, QWhereClause> {
  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProdottoIsarQueryFilter
    on QueryBuilder<ProdottoIsar, ProdottoIsar, QFilterCondition> {
  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> codiceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'codice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      codiceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'codice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      codiceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'codice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> codiceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'codice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      codiceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'codice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      codiceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'codice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      codiceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'codice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> codiceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'codice',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      codiceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'codice',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      codiceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'codice',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'howToTake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'howToTake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'howToTake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'howToTake',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'howToTake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'howToTake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'howToTake',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'howToTake',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'howToTake',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      howToTakeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'howToTake',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'immagine',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'immagine',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'immagine',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'immagine',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'immagine',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'immagine',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'immagine',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'immagine',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'immagine',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      immagineIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'immagine',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ingredients',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ingredients',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ingredients',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ingredients',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      ingredientsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ingredients',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> minsanEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minsan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      minsanGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minsan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      minsanLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minsan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> minsanBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minsan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      minsanStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'minsan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      minsanEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'minsan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      minsanContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'minsan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> minsanMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'minsan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      minsanIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minsan',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      minsanIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'minsan',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> nomeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      nomeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> nomeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> nomeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nome',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      nomeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> nomeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> nomeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> nomeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nome',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      nomeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nome',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      nomeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nome',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> pezziEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pezzi',
        value: value,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      pezziGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pezzi',
        value: value,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> pezziLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pezzi',
        value: value,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition> pezziBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pezzi',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rendibile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rendibile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rendibile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rendibile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rendibile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rendibile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rendibile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rendibile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rendibile',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rendibile',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rendibile',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rendibile',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rendibile',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rendibile',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rendibile',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      rendibileLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rendibile',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tipoProdotto',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tipoProdotto',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipoProdotto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tipoProdotto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tipoProdotto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tipoProdotto',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tipoProdotto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tipoProdotto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tipoProdotto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tipoProdotto',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipoProdotto',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tipoProdotto',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tipoProdottoDettaglio',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tipoProdottoDettaglio',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipoProdottoDettaglio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tipoProdottoDettaglio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tipoProdottoDettaglio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tipoProdottoDettaglio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tipoProdottoDettaglio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tipoProdottoDettaglio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tipoProdottoDettaglio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tipoProdottoDettaglio',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipoProdottoDettaglio',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      tipoProdottoDettaglioIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tipoProdottoDettaglio',
        value: '',
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      vendibileEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vendibile',
        value: value,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      vendibileGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vendibile',
        value: value,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      vendibileLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vendibile',
        value: value,
      ));
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterFilterCondition>
      vendibileBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vendibile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProdottoIsarQueryObject
    on QueryBuilder<ProdottoIsar, ProdottoIsar, QFilterCondition> {}

extension ProdottoIsarQueryLinks
    on QueryBuilder<ProdottoIsar, ProdottoIsar, QFilterCondition> {}

extension ProdottoIsarQuerySortBy
    on QueryBuilder<ProdottoIsar, ProdottoIsar, QSortBy> {
  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByCodice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'codice', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByCodiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'codice', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByHowToTake() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'howToTake', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByHowToTakeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'howToTake', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByImmagine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'immagine', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByImmagineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'immagine', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByIngredients() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ingredients', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      sortByIngredientsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ingredients', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByMinsan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minsan', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByMinsanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minsan', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByNome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByNomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByPezzi() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pezzi', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByPezziDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pezzi', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByTipoProdotto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoProdotto', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      sortByTipoProdottoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoProdotto', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      sortByTipoProdottoDettaglio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoProdottoDettaglio', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      sortByTipoProdottoDettaglioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoProdottoDettaglio', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByVendibile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vendibile', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> sortByVendibileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vendibile', Sort.desc);
    });
  }
}

extension ProdottoIsarQuerySortThenBy
    on QueryBuilder<ProdottoIsar, ProdottoIsar, QSortThenBy> {
  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByCodice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'codice', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByCodiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'codice', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByHowToTake() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'howToTake', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByHowToTakeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'howToTake', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByImmagine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'immagine', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByImmagineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'immagine', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByIngredients() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ingredients', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      thenByIngredientsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ingredients', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByMinsan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minsan', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByMinsanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minsan', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByNome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByNomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByPezzi() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pezzi', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByPezziDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pezzi', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByTipoProdotto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoProdotto', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      thenByTipoProdottoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoProdotto', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      thenByTipoProdottoDettaglio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoProdottoDettaglio', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy>
      thenByTipoProdottoDettaglioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoProdottoDettaglio', Sort.desc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByVendibile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vendibile', Sort.asc);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QAfterSortBy> thenByVendibileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vendibile', Sort.desc);
    });
  }
}

extension ProdottoIsarQueryWhereDistinct
    on QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> {
  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByCodice(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'codice', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByHowToTake(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'howToTake', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByImmagine(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'immagine', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByIngredients(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ingredients', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByMinsan(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minsan', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByNome(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nome', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByPezzi() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pezzi');
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByRendibile() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rendibile');
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByTipoProdotto(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipoProdotto', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct>
      distinctByTipoProdottoDettaglio({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipoProdottoDettaglio',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProdottoIsar, ProdottoIsar, QDistinct> distinctByVendibile() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vendibile');
    });
  }
}

extension ProdottoIsarQueryProperty
    on QueryBuilder<ProdottoIsar, ProdottoIsar, QQueryProperty> {
  QueryBuilder<ProdottoIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProdottoIsar, String, QQueryOperations> codiceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'codice');
    });
  }

  QueryBuilder<ProdottoIsar, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<ProdottoIsar, String, QQueryOperations> howToTakeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'howToTake');
    });
  }

  QueryBuilder<ProdottoIsar, String, QQueryOperations> immagineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'immagine');
    });
  }

  QueryBuilder<ProdottoIsar, String, QQueryOperations> ingredientsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ingredients');
    });
  }

  QueryBuilder<ProdottoIsar, String, QQueryOperations> minsanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minsan');
    });
  }

  QueryBuilder<ProdottoIsar, String, QQueryOperations> nomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nome');
    });
  }

  QueryBuilder<ProdottoIsar, int, QQueryOperations> pezziProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pezzi');
    });
  }

  QueryBuilder<ProdottoIsar, List<String>, QQueryOperations>
      rendibileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rendibile');
    });
  }

  QueryBuilder<ProdottoIsar, String?, QQueryOperations> tipoProdottoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipoProdotto');
    });
  }

  QueryBuilder<ProdottoIsar, String?, QQueryOperations>
      tipoProdottoDettaglioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipoProdottoDettaglio');
    });
  }

  QueryBuilder<ProdottoIsar, int, QQueryOperations> vendibileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vendibile');
    });
  }
}
