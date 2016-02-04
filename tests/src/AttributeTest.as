package
{
	import flexunit.framework.Assert;

	import talon.Attribute;
	import talon.Node;
	import talon.Node;
	import talon.utils.Gauge;

	public class AttributeTest
	{
		private var parent1:Node;
		private var parent2:Node;

		private var attribute:Attribute;
		private var changes:int;

		[Before]
		public function reset():void
		{
			changes = 0;

			var node:Node = new Node();
			attribute = node.getOrCreateAttribute("attribute");
			attribute.change.addListener(onAttributeValueChange);

			parent1 = new Node();
			var parent1Attribute:Attribute = parent1.getOrCreateAttribute("attribute");
			parent1Attribute.setted = "inheritFromParent1";

			parent2 = new Node();
			var parent2Attribute:Attribute = parent2.getOrCreateAttribute("attribute");
			parent2Attribute.setted = "inheritFromParent2";
		}

		private function onAttributeValueChange():void
		{
			changes++;
		}

		[Test]
		public function testBasic():void
		{
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
			// Pure
			attribute.setted = Attribute.INHERIT;
			attribute.isInheritable = true;
			Assert.assertTrue(attribute.isInheritable);
			Assert.assertFalse(attribute.isInherit);

			// Added to 1 parent
			parent1.addChild(attribute.node);
			Assert.assertTrue(attribute.isInherit);
			Assert.assertEquals(parent1.getOrCreateAttribute(attribute.name).value, attribute.value);

			// Removed from parent
			parent1.removeChild(attribute.node);
			Assert.assertFalse(attribute.isInherit);

			// Change parent form 1 to 2
			parent1.addChild(attribute.node);
			parent2.addChild(attribute.node);
			Assert.assertTrue(attribute.isInherit);
			Assert.assertEquals(parent2.getOrCreateAttribute(attribute.name).value, attribute.value);
		}

		[Test]
		public function testChangesWithoutParent():void
		{
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
			attribute.inited = "inited";
			Assert.assertEquals(1, changes);

			parent1.addChild(attribute.node);
			Assert.assertEquals(1, changes);

			attribute.isInheritable = true;
			Assert.assertEquals(1, changes);

			attribute.setted = Attribute.INHERIT;
			Assert.assertEquals(2, changes);

			parent1.removeChild(attribute.node);
			Assert.assertEquals(3, changes);
		}

		[Test]
		public function testCompositeAttribute():void
		{
			assertPadding("1",        "1", "1", "1", "1");
			assertPadding("1 2",      "1", "2", "1", "2");
			assertPadding("1 2 3",    "1", "2", "3", "2");
			assertPadding("1 2 3 4",  "1", "2", "3", "4");
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
	}
}
