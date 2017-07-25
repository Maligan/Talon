## Getting Started!

1. Download and install [Talon Browser]() from last release
2. Create new folder `helloworld`
3. Create new file `hello.xml` in `helloworld` folder:

	```xml
	<def ref="Hello">
		<label text="Hello World" />
	</def>
	```

4. Open folder with browser (via `File -> Open`)
5. Open file with browser (`Navigate -> Go To Template` or <kbd>Ctrl</kbd> + <kbd>P</kbd>) and you will see:  

	![](img/intro_1.png)

	Awesome! You did it!

## How browser works?

> Talon Browser follow [interactive programming](https://en.wikipedia.org/wiki/Interactive_programming) approach — it start watch any file within opened folder (recursively).  
And after any changes browser try to reload file and refresh result.

Lets create more complex example. For this add next three files into `helloworld` folder:

1. Template `button.xml`

	```xml
	<def ref="Button">
		<node class="button">
			<label text="Buy" />
			<image source="$coin" />
			<label text="3" />
		</node>
	</def>
	```
2. Stylesheet `button.css`

	```css
	.button {
		/* background */
		fill: #888888;
		/* font */
		fontName: Arial;
		fontSize: 14px;
		/* layout */
		padding: 8px;
		gap: 4px;
		/* mouse */
		cursor: button;
		touchMode: leaf;
		touchEvents: true;
	}

	.button:hover {
		fill: #8f8f8f;
	}

	.button:active {
		fill: #808080;
	}
	```

	Do not try to understand all of properties just now (they are not same as in W3C CSS) they are explained in [other articles](#whats-next).

3. And this carefully picked up coin image `coin.png`

	![coin](img/coin.png)

Each of files will be loaded and processed according to theirs content. From `button.xml` will be created new template — *Button*, styles from `style.css` will be merged to global style scope and `coin.png` will be loaded as picture.

Look at result:

![](img/intro_2.png)

## Templating
Advantages of [wise templating](https://en.wikipedia.org/wiki/Code_reuse#Criticism) are simplicity in apps, speed up development and in my opinion main one - saving developers nerves.

Template — reusable tree of elements. It can be *applied* at any **leaf** node of another template.

![Screenshot2](img/intro_4.png)

There are two sintax way to apply template in TML — *full* and *simple*, here we look at *simple* method.  
To do this, you need link template with tag name, see updated version of `button.xml`:

```xml
<def ref="Button" tag="button">
	<node class="button" label="Label">
		<label text="@label" />
		<image source="@icon" />
		<label text="@count" />
	</node>
</def>
```

Beside new `def` attribute `tag` you can notice attriubtes *binding* (via *@-notation*). If you are not familiar with [data binding](https://en.wikipedia.org/wiki/Data_binding) technique it's not a problem — *@-notation* just bind attribute to *template root* attribute. Binded attributes changes together.

Lets create one more template `popup.xml`:

```xml
<def ref="Popup">
	<node class="popup">
		<label text="You sure want to buy Vorpal Blade?" />
		<button label="Buy" icon="$coin" count="30" />
		<button label="Cancel" />
	</node>
</def>
```

And add same styles for beauty `popup.css`:

```css
.popup {
	fill: gray;
}
```

This is result:

![Screenshot2](img/intro_3.png)

## Import layouts into apps

If you use talon not only for mockups, once you need import you layouts into app. There are many ways to do it, let show easiest:

1. Pack to zip-archive layouts folder via `File -> Publish` (or <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>)
2. Place zip-archive into source path folder, add it to compile with `[Embed]` meta tag.
3. Load embedded data to `starling.extensions.TalonFactory`, and use it to instantiate template.

For example go change [Starling's First Steps: Create your Game](http://gamua.com/starling/first-steps/) application and expand it with talon facotry:

```actionscript
import starling.display.Sprite;

import talon.utils.TalonFactory;

public class Game extends Sprite
{
	[Embed(source="helloworld.zip")]
	private static const helloworld_zip:Class;

    public function Game()
    {
		var factory:TalonFactory = new TalonFactory();

		factory.importArchiveAsync(new helloworld_zip(), function():void
		{
			addChild(_factory.build("Popup") as Sprite);
		}
    }
}
```

Build and run the app, if you are lucky then you can see:

![](img/intro_5.png)

Easy.

## What's next?
After this introduction article I recommend you checkout detailed [documentation](./index.md). For quick explore talon's features you can read next part of documentation first:
* [Background](./background.md) — main way to display pictures
* [Layouts](./layouts.md) — how to position elements respect each other and free parent space
* [CSS Dialect](./css.md) — list of **all** attributes implemented within talon
