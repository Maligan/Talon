package designer.commands
{
	public class CloseCommand extends DesignerCommand
	{
		public override function execute():void
		{
			DesignerApplication.current.controller.setCurrentDocument(null);
		}
	}
}
