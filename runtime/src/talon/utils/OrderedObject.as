package talon.utils
{
    import flash.utils.Proxy;
    import flash.utils.flash_proxy;

    use namespace flash_proxy;

    public dynamic class OrderedObject extends Proxy
    {
        private var _reorderByUpdate:Boolean;
        private var _source:Object;
        private var _properties:Vector.<QName>;

        public function OrderedObject(source:Object = null, reorderByUpdate:Boolean = true)
        {
            _source = source || {};
            _reorderByUpdate = reorderByUpdate;
            _properties = new Vector.<QName>();
        }

        /** Because QName doesn't matched with '===' within vector indexOf() method. */
        private function indexOf(name:*):int
        {
            for (var i:int = 0; i < _properties.length; i++)
                if (_properties[i] == name)
                    return i;

            return -1;
        }

        flash_proxy override function setProperty(name:*, value:*):void
        {
            var oldValue:* = _source[name];
            if (oldValue != value) _source[name] = value;

            var index:int = indexOf(name);
            if (index == -1)
                _properties[_properties.length] = name;
            else if (_reorderByUpdate)
                _properties[_properties.length-1] = _properties.removeAt(index) as QName;
        }

        flash_proxy override function deleteProperty(name:*):Boolean
        {
            var deleted:Boolean = delete _source[name];
            if (deleted) _properties.removeAt(indexOf(name));

            return deleted;
        }

        flash_proxy override function getProperty(name:*):* { return _source[name]; }
        flash_proxy override function callProperty(name:*, ...rest):* { return _source[name].apply(_source, rest); }
        flash_proxy override function hasProperty(name:*):Boolean { return _source.hasOwnProperty(name); }
        flash_proxy override function nextName(index:int):String { return String(_properties[index - 1]); }
        flash_proxy override function nextNameIndex(index:int):int { return (index < _properties.length) ? (index + 1) : 0; }
        flash_proxy override function nextValue(index:int):* { return _source[_properties[index - 1]]; }
    }
}