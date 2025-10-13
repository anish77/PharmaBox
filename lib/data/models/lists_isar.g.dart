// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetListsIsarCollection on Isar {
  IsarCollection<ListsIsar> get listsIsars => this.collection();
}

const ListsIsarSchema = CollectionSchema(
  name: r'ListsIsar',
  id: 2997137478126889166,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.string,
    ),
    r'isCompleted': PropertySchema(
      id: 1,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'nameList': PropertySchema(
      id: 2,
      name: r'nameList',
      type: IsarType.string,
    )
  },
  estimateSize: _listsIsarEstimateSize,
  serialize: _listsIsarSerialize,
  deserialize: _listsIsarDeserialize,
  deserializeProp: _listsIsarDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'products': LinkSchema(
      id: -7605042969787000326,
      name: r'products',
      target: r'ProdottoIsar',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _listsIsarGetId,
  getLinks: _listsIsarGetLinks,
  attach: _listsIsarAttach,
  version: '3.1.0+1',
);

int _listsIsarEstimateSize(
  ListsIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.date.length * 3;
  bytesCount += 3 + object.nameList.length * 3;
  return bytesCount;
}

void _listsIsarSerialize(
  ListsIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.date);
  writer.writeBool(offsets[1], object.isCompleted);
  writer.writeString(offsets[2], object.nameList);
}

ListsIsar _listsIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ListsIsar();
  object.date = reader.readString(offsets[0]);
  object.id = id;
  object.isCompleted = reader.readBool(offsets[1]);
  object.nameList = reader.readString(offsets[2]);
  return object;
}

P _listsIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _listsIsarGetId(ListsIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _listsIsarGetLinks(ListsIsar object) {
  return [object.products];
}

void _listsIsarAttach(IsarCollection<dynamic> col, Id id, ListsIsar object) {
  object.id = id;
  object.products
      .attach(col, col.isar.collection<ProdottoIsar>(), r'products', id);
}

extension ListsIsarQueryWhereSort
    on QueryBuilder<ListsIsar, ListsIsar, QWhere> {
  QueryBuilder<ListsIsar, ListsIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ListsIsarQueryWhere
    on QueryBuilder<ListsIsar, ListsIsar, QWhereClause> {
  QueryBuilder<ListsIsar, ListsIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<ListsIsar, ListsIsar, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterWhereClause> idBetween(
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

extension ListsIsarQueryFilter
    on QueryBuilder<ListsIsar, ListsIsar, QFilterCondition> {
  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> isCompletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> nameListEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameList',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> nameListGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameList',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> nameListLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameList',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> nameListBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameList',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> nameListStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameList',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> nameListEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameList',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> nameListContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameList',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> nameListMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameList',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> nameListIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameList',
        value: '',
      ));
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition>
      nameListIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameList',
        value: '',
      ));
    });
  }
}

extension ListsIsarQueryObject
    on QueryBuilder<ListsIsar, ListsIsar, QFilterCondition> {}

extension ListsIsarQueryLinks
    on QueryBuilder<ListsIsar, ListsIsar, QFilterCondition> {
  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> products(
      FilterQuery<ProdottoIsar> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'products');
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition>
      productsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'products', length, true, length, true);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition> productsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'products', 0, true, 0, true);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition>
      productsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'products', 0, false, 999999, true);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition>
      productsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'products', 0, true, length, include);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition>
      productsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'products', length, include, 999999, true);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterFilterCondition>
      productsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'products', lower, includeLower, upper, includeUpper);
    });
  }
}

extension ListsIsarQuerySortBy on QueryBuilder<ListsIsar, ListsIsar, QSortBy> {
  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> sortByNameList() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameList', Sort.asc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> sortByNameListDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameList', Sort.desc);
    });
  }
}

extension ListsIsarQuerySortThenBy
    on QueryBuilder<ListsIsar, ListsIsar, QSortThenBy> {
  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> thenByNameList() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameList', Sort.asc);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QAfterSortBy> thenByNameListDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameList', Sort.desc);
    });
  }
}

extension ListsIsarQueryWhereDistinct
    on QueryBuilder<ListsIsar, ListsIsar, QDistinct> {
  QueryBuilder<ListsIsar, ListsIsar, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QDistinct> distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<ListsIsar, ListsIsar, QDistinct> distinctByNameList(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameList', caseSensitive: caseSensitive);
    });
  }
}

extension ListsIsarQueryProperty
    on QueryBuilder<ListsIsar, ListsIsar, QQueryProperty> {
  QueryBuilder<ListsIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ListsIsar, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<ListsIsar, bool, QQueryOperations> isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<ListsIsar, String, QQueryOperations> nameListProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameList');
    });
  }
}
