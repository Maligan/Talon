package
{
	import flexunit.framework.Assert;

	import talon.core.Attribute;
	import talon.core.Node;

	public class AttributeTest
	{
		private var node:Node;
		private var node1:Node;
		private var node2:Node;

		private var attribute:Attribute;
		private var changes:int;

		private function resetNonStyleable():void { reset(Attribute.ID); }
		private function resetStyleable():void { reset(Attribute.ALPHA); }
		private function resetInheritable():void { reset(Attribute.FONT_NAME); }

		private function reset(name:String):void
		{
			changes = 0;

			node = new Node();
			attribute = node.getOrCreateAttribute(name);
			attribute.change.addListener(onAttributeValueChange);

			node1 = new Node();
			var parent1Attribute:Attribute = node1.getOrCreateAttribute(name);
			parent1Attribute.setted = "inheritFromParent1";

			node2 = new Node();
			var parent2Attribute:Attribute = node2.getOrCreateAttribute(name);
			parent2Attribute.setted = "inheritFromParent2";
		}

		private function onAttributeValueChange():void
		{
			changes++;
		}

		[Test]
		public function testSetters():void
		{
			resetStyleable();

			attribute.inited = "inited";
			attribute.styled = "styled";
			attribute.setted = "setted";

			Assert.assertEquals("inited", attribute.inited);
			Assert.assertEquals("styled", attribute.styled);
			Assert.assertEquals("setted", attribute.setted);
		}

		[Test]
		public function testSettersPriority():void
		{
			resetNonStyleable();
			attribute.inited = "inited";
			Assert.assertEquals(attribute.inited, attribute.value);
			attribute.styled = "styled";
			Assert.assertEquals(attribute.inited, attribute.value);
			attribute.setted = "setted";
			Assert.assertEquals(attribute.setted, attribute.value);

			resetStyleable();
			attribute.inited = "inited";
			Assert.assertEquals(attribute.inited, attribute.value);
			attribute.styled = "styled";
			Assert.assertEquals(attribute.styled, attribute.value);
			attribute.setted = "setted";
			Assert.assertEquals(attribute.setted, attribute.value);
		}

		[Test]
		public function testInherit():void
		{
			resetInheritable();

			// Pure
			attribute.setted = Attribute.INHERIT;
			Assert.assertTrue(attribute.isInheritable);
			Assert.assertFalse(attribute.isInherit);

			// Added to 1 parent
			node1.addChild(attribute.node);
			Assert.assertTrue(attribute.isInherit);
			Assert.assertEquals(node1.getOrCreateAttribute(attribute.name).value, attribute.value);

			// Removed from parent
			node1.removeChild(attribute.node);
			Assert.assertFalse(attribute.isInherit);

			// Change parent to 2
			node2.addChild(attribute.node);
			Assert.assertTrue(attribute.isInherit);
			Assert.assertEquals(node2.getOrCreateAttribute(attribute.name).value, attribute.value);
		}

		[Test]
		public function testChangesWithoutParent():void
		{
			resetStyleable();

			attribute.inited = "inited";
			Assert.assertEquals(1, changes);

			attribute.styled = "styled";
			Assert.assertEquals(2, changes);

			attribute.setted = "setted";
			Assert.assertEquals(3, changes);

			attribute.styled = "styled#2";
			Assert.assertEquals(3, changes);

			attribute.setted = null;
			Assert.assertEquals(4, changes);

			attribute.styled = null;
			Assert.assertEquals(5, changes);
		}

		[Test]
		public function testChangesWithParent():void
		{
			reset(Attribute.FONT_NAME);

			attribute.inited = "inited";
			Assert.assertEquals(1, changes);

			node1.addChild(attribute.node);
			Assert.assertEquals(1, changes);

			attribute.setted = Attribute.INHERIT;
			Assert.assertEquals(2, changes);

			node1.setAttribute(attribute.name, "inheritFromParent1_setted");
			Assert.assertEquals(3, changes);

			node1.removeChild(attribute.node);
			Assert.assertEquals(4, changes);
		}

		[Test]
		public function testCompositeAttribute():void
		{
			// Quad format
			assertPadding("1",        "1", "1", "1", "1");
			assertPadding("1 2",      "1", "2", "1", "2");
			assertPadding("1 2 3",    "1", "2", "3", "2");
			assertPadding("1 2 3 4",  "1", "2", "3", "4");

			// Pair format
			assertFillMode("repeat",         "repeat",  "repeat");
			assertFillMode("stretch",        "stretch", "stretch");
			assertFillMode("stretch repeat", "stretch", "repeat");
		}

		private function assertPadding(padding:String, top:String, right:String, bottom:String, left:String):void
		{
			var node:Node;

			// Direct
			node = new Node();
			node.setAttribute(Attribute.PADDING, padding);
			Assert.assertEquals(top, node.getAttributeCache(Attribute.PADDING_TOP));
			Assert.assertEquals(right, node.getAttributeCache(Attribute.PADDING_RIGHT));
			Assert.assertEquals(bottom, node.getAttributeCache(Attribute.PADDING_BOTTOM));
			Assert.assertEquals(left, node.getAttributeCache(Attribute.PADDING_LEFT));

			// Reverse
			node = new Node();
			node.setAttribute(Attribute.PADDING_TOP, top);
			node.setAttribute(Attribute.PADDING_RIGHT, right);
			node.setAttribute(Attribute.PADDING_BOTTOM, bottom);
			node.setAttribute(Attribute.PADDING_LEFT, left);
			Assert.assertEquals(padding, node.getAttributeCache(Attribute.PADDING));
		}

		private function assertFillMode(fillMode:String, horizontal:String, vertical:String):void
		{
			var node:Node;

			// Direct
			node = new Node();
			node.setAttribute(Attribute.FILL_MODE, fillMode);
			Assert.assertEquals(horizontal, node.getAttributeCache(Attribute.FILL_MODE_HORIZONTAL));
			Assert.assertEquals(vertical, node.getAttributeCache(Attribute.FILL_MODE_VERTICAL));

			// Reverse
			node = new Node();
			node.setAttribute(Attribute.FILL_MODE_HORIZONTAL, horizontal);
			node.setAttribute(Attribute.FILL_MODE_VERTICAL, vertical);
			Assert.assertEquals(fillMode, node.getAttributeCache(Attribute.FILL_MODE));
		}
	}
}
















