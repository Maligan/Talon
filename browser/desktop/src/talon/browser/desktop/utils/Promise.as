package talon.browser.desktop.utils
{
	/**
	 * Promises/A+ compatible implementation.
	 * @see https://github.com/promises-aplus/promises-spec
	 * @author: maligan (maligan@rambler.ru)
	 * @version: 0.9
	 */
	public class Promise
	{
		/** Promise Resolution Procedure. */
		private static function resolveProcedure(promise:Promise, result:Object, state:String):void
		{
			if (result == promise)
				promise.resolve(new TypeError(), REJECTED);

			else if (result is Promise)
				Promise(result).then(promise.fulfill, promise.reject);

			else
				promise.resolve(result, state);
		}

		private static const PENDING:String = "pending";
		private static const FULFILLED:String = "fulfilled";
		private static const REJECTED:String = "rejected";

		private var _state:String;
		private var _result:Object;
		private var _reactions:Vector.<Promise>;

		private var _onFulfilled:Function;
		private var _onRejected:Function;

		public function Promise(executor:Function = null)
		{
			_state = PENDING;
			_reactions = new Vector.<Promise>();
			if (executor) invokeExecutor(executor);
		}

		public function then(onFulfilled:Function = null, onRejected:Function = null):Promise
		{
			onFulfilled ||= identity;
			onRejected  ||= thrower;

			var reaction:Promise = new Promise();
			reaction._onFulfilled = onFulfilled;
			reaction._onRejected = onRejected;

			if (_state != PENDING)
				invokeReaction(reaction);
			else
				_reactions[_reactions.length] = reaction;

			return reaction;
		}

		private function identity(value:Object):Object
		{
			return value;
		}

		private function thrower(value:Object):void
		{
			throw value;
		}

		// invocations

		private function invokeExecutor(executor:Function):void
		{
			try
			{
				if (executor.length == 1)
					executor(fulfill);
				else if (executor.length == 2)
					executor(fulfill, reject);
			}
			catch(e:*)
			{
				reject(e);
			}
		}

		private function invokeReaction(reaction:Promise):void
		{
			try
			{
				var func:Function = _state==FULFILLED ? reaction._onFulfilled : reaction._onRejected;
				var funcResult:Object = func.length==0 ? func() : func(_result);
				reaction.fulfill(funcResult);
			}
			catch (e:*)
			{
				reaction.reject(e)
			}
		}

		// resolve

		public function fulfill(value:Object = null):void
		{
			resolveProcedure(this, value, FULFILLED);
		}

		public function reject(reason:Object = null):void
		{
			resolveProcedure(this, reason, REJECTED);
		}

		private function resolve(value:Object, state:String):void
		{
			if (_state == PENDING)
			{
				_state = state;
				_result = value;

				while (_reactions.length)
					invokeReaction(_reactions.shift());
			}
		}
	}
}
