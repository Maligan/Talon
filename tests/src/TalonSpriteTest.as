package
{
	import starling.extensions.TalonSprite;

	public class TalonSpriteTest
	{
		[Test]
		public function testParentChange():void
		{
			var parent1:TalonSprite = new TalonSprite();
			var parent2:TalonSprite = new TalonSprite();
			var child:TalonSprite = new TalonSprite();

			parent1.addChild(child);
			parent2.addChild(child);

			parent1.removeChildren();
			parent2.removeChildren();
		}
	}
}
