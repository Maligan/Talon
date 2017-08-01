package talon.utils
{
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	use namespace flash_proxy;

    [ExcludeClass]
    public dynamic class OrderedObject extends Proxy
    {
        protected var _source:Object;
		protected var _reorderAfterUpdate:Boolean;
		protected var _order:Vector.<QName>;

        public function OrderedObject(reorderAfterUpdate:Boolean = true)
        {
            _source = {};
            _reorderAfterUpdate = reorderAfterUpdate;
            _order = new Vector.<QName>();
        }

        /** Because QName doesn't matched with '===' within vector indexOf() method. */
        private function indexOf(name:*):int
        {
            for (var i:int = 0; i < _order.length; i++)
                if (_order[i] == name)
                    return i;

            return -1;
        }

        flash_proxy override function setProperty(name:*, value:*):void
        {
            var oldValue:* = _source[name];
            if (oldValue != value) _source[name] = value;

            var index:int = indexOf(name);
            if (index == -1)
                _order[_order.length] = name;
            else if (_reorderAfterUpdate)
                _order[_order.length-1] = _order.removeAt(index) as QName;
        }

        flash_proxy override function deleteProperty(name:*):Boolean
        {
            var deleted:Boolean = delete _source[name];
            if (deleted) _order.removeAt(indexOf(name));

            return deleted;
        }

        flash_proxy override function getProperty(name:*):* { return _source[name]; }
        flash_proxy override function callProperty(name:*, ...rest):* { return _source[name].apply(_source, rest); }
        flash_proxy override function hasProperty(name:*):Boolean { return _source.hasOwnProperty(name); }
        flash_proxy override function nextName(index:int):String { return String(_order[index - 1]); }
        flash_proxy override function nextNameIndex(index:int):int { return (index < _order.length) ? (index + 1) : 0; }
        flash_proxy override function nextValue(index:int):* { return _source[_order[index - 1]]; }
    }
}