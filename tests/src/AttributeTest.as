package
{
	import flexunit.framework.Assert;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.Gauge;

	public class AttributeTest
	{
		private var parent1:Node;
		private var parent2:Node;

		private var attribute:Attribute;
		private var changes:int;

		private var gauge:Gauge;

		[Before]
		public function reset():void
		{
			changes = 0;
			gauge = new Gauge();

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
		public function testIsStyleable():void
		{
			attribute.inited = "inited";
			attribute.styled = "styled";
			attribute.isStyleable = false;

			Assert.assertEquals(attribute.inited, attribute.value);
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
		public function testChanges():void
		{
			// Basic
			attribute.inited = "inited";
			Assert.assertEquals(1, changes);

			attribute.styled = "styled";
			Assert.assertEquals(2, changes);

			attribute.setted = "setted";
			Assert.assertEquals(3, changes);

			attribute.styled = "styled#2";
			Assert.assertEquals(3, changes);

			// With inherit
			parent1.addChild(attribute.node);
			Assert.assertEquals(3, changes);

			attribute.isInheritable = true;
			Assert.assertEquals(3, changes);

			attribute.setted = Attribute.INHERIT;
			Assert.assertEquals(4, changes);

			parent1.removeChild(attribute.node);
			Assert.assertEquals(5, changes);
		}

		[Test]
		public function testBindingToGauge():void
		{
			attribute.addBinding(attribute.change, attribute.getValue, gauge.parse);
			attribute.addBinding(gauge.change, gauge.toString, attribute.setSetted);

			attribute.setted = "100px";
			Assert.assertEquals(attribute.value, gauge.toString());

			gauge.amount = 30;
			gauge.unit = Gauge.DP;
			Assert.assertEquals(attribute.value, gauge.toString());
		}
	}
}
