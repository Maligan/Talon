package
{
	import starling.extensions.TalonSpriteElement;

	public class TalonSpriteElementTest
	{
		[Test]
		public function testParentChange():void
		{
			var parent1:TalonSpriteElement = new TalonSpriteElement();
			var parent2:TalonSpriteElement = new TalonSpriteElement();
			var child:TalonSpriteElement = new TalonSpriteElement();

			parent1.addChild(child);
			parent2.addChild(child);

			parent1.removeChildren();
			parent2.removeChildren();
		}
	}
}
