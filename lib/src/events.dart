library events;

typedef void Listener(event);

class Event {
  String type;
  Event(this.type);
}

class Events {

  Map<String, ListenerList> _listeners;

  Events() : _listeners = <ListenerList>{};

  ListenerList operator [](String type) => _listeners.putIfAbsent(type, () => new ListenerList(type));

  removeAllListeners() => _listeners = {};
}

abstract class Emitter<E extends Events>{

  E on;

}

class ListenerList {

  final String _type;

  final List<Listener> _listeners;

  ListenerList(this._type) : _listeners = <Listener>[];

  ListenerList add(Listener listener) {
    _add(listener);
    return this;
  }

  ListenerList remove(Listener listener) {
    _remove(listener);
    return this;
  }

  bool dispatch([evt]) {
    //assert(evt.type == _type);
    _listeners.forEach((l) => l(evt));
  }

  void _add(Listener listener) {
    _listeners.add(listener);
  }

  void _remove(Listener listener) {
    _listeners.removeRange(_listeners.indexOf(listener), 1);
  }

  int get length => _listeners.length;

  bool get isEmpty => _listeners.isEmpty;
}

