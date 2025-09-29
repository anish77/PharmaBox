import 'package:pharma_box/data/constants.dart';

enum SearchKind { prodotti, ean, lottiInvendibili, immagine, bugiardino, bugiardinoparafarmaco }

class _SoapConfig {
  const _SoapConfig({
    required this.dataset,
    required this.filterKey,
  });

  final String dataset;
  final String filterKey;
}

const Map<SearchKind, _SoapConfig> _soapConfigs = {
  SearchKind.prodotti: _SoapConfig(dataset: 'TR001', filterKey: 'FDI_0004'),
  SearchKind.ean: _SoapConfig(dataset: 'TR016', filterKey: 'FDI_0002'),
  SearchKind.lottiInvendibili:
      _SoapConfig(dataset: 'TR_LOTTI_INV', filterKey: 'FDI_0001'),
  SearchKind.immagine: _SoapConfig(dataset: 'TDZ', filterKey: 'FDI_T218'),
  SearchKind.bugiardino: _SoapConfig(dataset: 'TDF', filterKey: 'FDI_T218'),
  SearchKind.bugiardinoparafarmaco: _SoapConfig(dataset: 'TD1', filterKey: 'FDI_T218')
};

String buildSearchXml(String query, {SearchKind kind = SearchKind.prodotti}) {
  final config = _soapConfigs[kind]!;
  final filterKey = kind == SearchKind.prodotti && int.tryParse(query) != null
      ? 'FDI_0001'
      : config.filterKey;

  return _buildExecuteQueryEnvelope(
    dataset: config.dataset,
    filterKey: filterKey,
    filterValue: query,
  );
}

String _buildExecuteQueryEnvelope({
  required String dataset,
  required String filterKey,
  required String filterValue,
}) {
  return '''
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://webservices.farmadati.it" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:fdiw="http://schemas.datacontract.org/2004/07/FDIWebServices">
  <soapenv:Header/>
  <soapenv:Body>
    <web:ExecuteQuery>
      <web:Username>$kFarmadatiUsername</web:Username>
      <web:Password>$kFarmadatiPassword</web:Password>
      <web:CodiceSetDati>$dataset</web:CodiceSetDati>
      <web:CampiDaEstrarre>
        <arr:string>ALL</arr:string>
      </web:CampiDaEstrarre>
      <web:Filtri>
        <fdiw:Filter>
          <fdiw:Key>$filterKey</fdiw:Key>
          <fdiw:Operator>CONTIENE</fdiw:Operator>
          <fdiw:Value>$filterValue</fdiw:Value>
        </fdiw:Filter>
      </web:Filtri>
      <web:PageN>1</web:PageN>
      <web:PagingN>100</web:PagingN>
    </web:ExecuteQuery>
  </soapenv:Body>
</soapenv:Envelope>
''';
}
