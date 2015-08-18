package talon.utils
{
	public function pad(parent:Number, child:Number, before:Number, after:Number, mode:Number):Number
	{
		switch (mode)
		{
			case 0:    return before;
			case 0.5:  return before + (parent - child) / 2;
			case 1:    return before + (parent - child);
			default:   return 0;
		}
	}
}