package starling.extensions
{
	import talon.core.Node;

	public interface ITalonDisplayObject
	{
		/** Select elements from display tree.
		 *  In case <code>selector</code> equals null, simple return query with one current object.
		 * 
		 *  @param CSS selector supported by talon
		 */
		function query(selector:String = null):TalonQuery;

//		+ validate()
//		+ getAttribute()
//		+ setAttribute()
//		+ setResources()
//		+ setStyles()
//		+ rectangle
		
		/** @private */
		function get node():Node
	}
}