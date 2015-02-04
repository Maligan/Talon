package designer.commands
{
	import starling.core.Starling;

	public class StatsCommand extends DesignerCommand
	{
		public override function execute():void
		{
			Starling.current.showStats = !Starling.current.showStats;
		}

		public override function get isActive():Boolean
		{
			return Starling.current.showStats;
		}
	}
}
