import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

abstract class ListWithIdsReactiveRepository<T> {
  final updater = PublishSubject<Null>();

  Future<List<String>> getRawData();

  Future<bool> saveRawData(final List<String> items);

  T convertFromString(final String rawItem);

  String convertToString(final T item);

  dynamic getId(final T item);

  Future<List<T>> getItems() async {
    final rawItems = await getRawData();
    return rawItems.map((rawItem) => convertFromString(rawItem)).toList();
  }

  Future<bool> setItems(final List<T> items) async {
    final rawItems = items.map((item) => convertToString(item)).toList();
    return _setRawItems(rawItems);
  }

  Stream<List<T>> observeItems() async* {
    yield await getItems();
    await for (final _ in updater) {
      yield await getItems(); //добавление нового зн-ия
    }
  }

  Future<bool> addItem(final T item) async {
    final items = await getItems();
    items.add(item);
    return setItems(items);
  }

  Future<bool> removeItem(final T item) async {
    final items = await getItems();
    items.remove(item);
    return setItems(items);
  }

  Future<bool> addItemsOrReplaceById(final T newItem) async {
    final items = await getItems();
    final itemIndex = items.indexWhere((item) => getId(item) == getId(newItem));
    if (itemIndex == -1) {
      items.add(newItem);
    } else {
      items[itemIndex] = newItem;
    }
    return setItems(items);
  }

  Future<bool> removeFromItemsById(final dynamic id) async {
    final items = await getItems();
    items.removeWhere((item) => getId(item) == id);
    return setItems(items);
  }

  Future<T?> getItemById(final dynamic id) async {
    final items = await getItems();
    return items.firstWhereOrNull((item) => getId(item) == id);
  }

  Future<bool> _setRawItems(final List<String> rawItems) async {
    updater.add(null); //уведомление о новом зн-ии
    return saveRawData(rawItems);
  }
}
