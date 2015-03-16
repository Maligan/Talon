package
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.System;
	import flash.utils.Dictionary;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;

	import starling.events.Event;

	import talon.Attribute;
	import talon.types.Gauge;

	import talon.types.GaugeQuad;

	import talon.Node;

	import talon.starling.SpriteElement;
	import talon.utils.TMLParser;
	import talon.utils.TalonFactory;
	import talon.utils.StringUtil;
	import starling.textures.Texture;

	[SWF(backgroundColor="#444444", width="800", height="500")]
	public class TalonDebugStartup extends MovieClip
	{
		[Embed(source="../assets/up.png")] private static const UP_BYTES:Class;
		[Embed(source="../assets/over.png")] private static const OVER_BYTES:Class;
		[Embed(source="../assets/down.png")] private static const DOWN_BYTES:Class;

		private var _document:Sprite;
		private var _talon:SpriteElement;

		public function TalonDebugStartup()
		{
//			stage.addEventListener(Event.RESIZE, onResize);

//			function traceTree(node:Node, level:int = 0):void
//			{
//				trace(mul("----", level), node.getAttribute("type"), "(" + node.getAttribute("id") + ")");
//				for (var i:int = 0; i < node.numChildren; i++) traceTree(node.getChildAt(i), level+1);
//			}
//
//			function mul(str:String, value:int):String
//			{
//				var array:Array = new Array(value);
//				for (var i:int = 0; i < value; i++) array[i] = str;
//				return array.join("");
//			}


//			var string:String = "res(key)";
//
//			var timer:int = getTimer();
//
//			for (var i:int = 0; i < 1000000; i++)
//			{
//				StringUtil.parseFunction(string) == null;
//			}

//			throw new Error("timer: " + ((getTimer() - timer)/1000).toFixed(2) + "sec");
//			trace("tmp"); // 0.6 - 0.7


//			var scope:Object = {};
//
//			scope["button"] =
//				<node id="button_root">
//					<image id="button_icon" color="!default" />
//					<node id="button_container">
//						<image id="BC1" />
//						<image id="BC2" />
//						<image id="BC3" />
//					</node>
//					<label id="button_label" />
//				</node>;
//
//			scope["buttonOverride"] =
//				<button>
//					<rewrite ref="BC3" mode="replace">
//						<image id="REPLACER" />
//					</rewrite>
//					<rewrite ref="button_icon" mode="attributes" color="!red" />
//				</button>;
//
//			scope["buttonOverride2"] =
//				<buttonOverride>
//					<rewrite ref="button_icon" mode="attributes" color="!blue" />
//				</buttonOverride>;
//
//			scope["tree1"] =
//				<node id="tree1_root">
//					<node id="child1" />
//					<node id="child2" />
//					<node id="child3" />
//					<buttonOverride2 id="secondButton">
//						<rewrite ref="button_icon" mode="attributes" color="!gray" />
//					</buttonOverride2>
//				</node>;
//
//
//			var parser:TMLParser = new TMLParser(scope, new <String>["node", "label", "image"]);
//			parser.parseTemplate("tree1");

			System.disposeXML(null);

			trace('sdf');
			return;

			Attribute.registerQueryAlias("url", url);

			var gauge:GaugeQuad = new GaugeQuad();
			gauge.parse("10px 10px 1em");

			var node:Node = new Node();
			node.setStyleSheet(null);
			node.setResources(null);

			new Starling(Sprite, stage);
			Starling.current.addEventListener(Event.ROOT_CREATED, onRootCreated);
			Starling.current.start();
			Starling.current.showStats = false;
		}

		private var _cache:Dictionary = new Dictionary();
		private function url(attr:Attribute, url:String):*
		{
			if (_cache[url] == null)
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
				loader.load(new URLRequest(url));
			}
			else if (_cache[url] is Loader)
			{
				return null;
			}
			else if (_cache[url] is Texture)
			{
				return _cache[url];
			}

			function onLoadComplete(e:*):void
			{
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
				_cache[url] = Texture.fromBitmap(loader.content as Bitmap);
				attr.node.dispatchEventWith(Event.CHANGE, false, attr.name);
			}
		}


		private function onResize(e:*):void
		{
			Starling.current.stage.stageWidth = stage.stageWidth;
			Starling.current.stage.stageHeight = stage.stageHeight;
			Starling.current.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);

			if (_talon != null)
			{
				_talon.node.bounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
				_talon.node.commit();
			}
		}

		private var _factory:TalonFactory;

		private function onRootCreated(e:Event):void
		{
			_document = Sprite(Starling.current.root);

			var css:String =
			<literal><![CDATA[

				node#container
				{
					gap: 4px;
					interline: 4px;
					padding: 4px;
					wrap: true;
				}

				/* Default button skin. */
				button:hover { backgroundImage: res(over); filter: glow(red, 3) }
				button:active { backgroundImage: res(down); }
				button
				{
					backgroundImage: res(up);
					background9Scale: 4px;
					cursor: button;

					halign: center;
					valign: center;
					clipping: true;

					fontName: Tahoma;
					fontSize: 11px;
					fontColor: #C9C9C9;
					padding: 1.25em 1.25em 1.25em 1.25em;

					minWidth: auto;
					width: *;
					minHeight: 20px;
				}

			]]></literal>.valueOf();

			var config:XML =
					<template id="root">
						<node layout="abs">
							<node position="50%" pivot="50%" orientation="horizontal" backgroundColor="silver" width="75%" height="auto" gap="0px" wrap="true" valign="bottom" halign="center">
								<node layout="abs" width="100px" height="50px" backgroundColor="red" margin="none 0px" />
								<node layout="abs" width="50px" height="100px" backgroundColor="blue" />
								<node layout="abs" width="*" height="50px" backgroundColor="gray" />
								<node layout="abs" width="50px" height="100px" backgroundColor="yellow" />
								<node layout="abs" width="2*" height="50px" margin="50px" backgroundColor="olive" />
								<node layout="abs" width="50px" height="100px" backgroundColor="black"  />
								<node layout="abs" width="100px" height="50px" backgroundColor="white" />
								<node layout="abs" width="50px" height="100px" backgroundColor="fuchsia" />
								<node layout="abs" width="100px" height="50px" backgroundColor="navy" />
							</node>
						</node>
					</template>;


//			<node id="root" width="100%" height="500px" layout="flow" padding="0.5em" valign="center" halign="center" orientation="vertical" gap="4px">
//				<label text="Urban fantasy online game with real world venues. Become a vampire, werewolf or shadow hunter!" height="auto"  fontSize="17px" fontName="Tahoma" marginBottom="0.5em" marginLeft="2px" halign="left" fontColor="#C9C9C9" width="*" />
//				<image src="url(http://images.clipartpanda.com/hulk-clip-art-d6fe7f8d430a063ff9a0682a33621a34.png)" />
//				<button><label text="Sed ut perspiciatis unde" /></button>
//				<button><label text="res(locale-string)" /></button>
//				<button><label text="Et harum quidem rerum facilis" /></button>
//			</node>;

			//<button><label text="Temporibus autem quibusdam" /></button>
			//<input multiline="true" width="auto" height="auto" halign="left" fontColor="#C9C9C9" fontName="Tahoma" fontSize="11px" text="Native Text Field" backgroundColor="#222222" />


			_factory = new TalonFactory();
			_factory.addTerminal("input", TalonInput);
			_factory.addTemplate(config);

			_factory.addStyleSheet(css);
			_factory.addResource("up", Texture.fromEmbeddedAsset(UP_BYTES));
			_factory.addResource("over", Texture.fromEmbeddedAsset(OVER_BYTES));
			_factory.addResource("down", Texture.fromEmbeddedAsset(DOWN_BYTES));
			_factory.addResource("locale-string", "Hello! I'm English text");

			_talon = _factory.build("root") as SpriteElement;
			_talon.addEventListener("invalidate", onInvalidate);
			_document.addChild(_talon);
			_document.addEventListener(Event.TRIGGERED, onTriggered);
			onResize(null)
		}

		private function onInvalidate():void
		{
			onResize(null);
		}

		private function onTriggered(e:Event):void
		{
			var container:DisplayObjectContainer = _talon.getChildByName("container") as DisplayObjectContainer;

			if (e.data == "add")
			{
				container.addChild(_factory.build("button", false, false));
				onResize(null)
			}
			else if (e.data == "remove")
			{
				if (container.numChildren == 0) return;
				container.removeChildAt(container.numChildren - 1);
				onResize(null)
			}
			else if (e.data == "remove_me")
			{
				container.removeChild(e.target as DisplayObject);
				onResize(null)
			}
		}
	}
}
