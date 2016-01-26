package
{
	import flexunit.framework.Assert;

	import talon.Attribute;
	import talon.Node;
	import talon.layout.Layout;

	public class LayoutAbsTest
	{
		private var parent:Node;
		private var child:Node;

		[Before]
		public function reset():void
		{
			child = new Node();
			child.setAttribute(Attribute.WIDTH, "32px");
			child.setAttribute(Attribute.HEIGHT, "64px");

			parent = new Node();
			parent.setAttribute(Attribute.LAYOUT, Layout.ABSOLUTE);
			parent.addChild(child);
		}

		[Test]
		public function testPosition():void
		{
			parent.bounds.setTo(0, 0, 1000, 1000);
			parent.commit();

			Assert.assertEquals(32, child.bounds.width);
			Assert.assertEquals(64, child.bounds.height);
		}
	}
}