## Getting Started!

1. Download and install [Talon Browser]() from last release
2. Create new folder `helloworld`
3. Create new file `hello.xml` in `helloworld` folder:

	```xml
	<def ref="hello">
		<label text="Hello World" />
	</def>
	```

4. Open folder with browser (via `File -> Open`)
5. Open file with browser (`Navigate -> Go To Template` or <kbd>Ctrl</kbd> + <kbd>P</kbd>) and you will see:  

	![Screenshot1](img/browser_1.png)

	Awesome! You did it!

## How browser works

> Talon Browser use [interactive programming](https://en.wikipedia.org/wiki/Interactive_programming) approach — it start watch any file within opened folder (recursively).  
And after any changes browser try to reload file and refresh result.

Lets create more complex example. For this add next three files into `helloworld` folder:

1. Template `button.xml`

	```xml
	<def ref="button">
		<node>
			<label text="Buy" />
			<image src="$coin" />
			<label text="3" />
		</node>
	</def>
	```
2. Stylesheet `style.css`

	```css
	node {
		fill: #888888;
		fontName: Arial;
		fontSize: 14px;
		padding: 8px;
		gap: 4px;
		touchMode: leaf;
		touchEvents: true;
		cursor: button;
	}

	node:hover {
		fill: #8f8f8f;
	}

	node:active {
		fill: #808080;
	}
	```

3. And this carefully picked up coin `coin.png`

	![coin](img/coin.png)

После добавления файлов в каталог браузер загрузил их о обработал: `button.xml` определил как файл-шаблона, `style.css` добавил в общее пространсто стилей и `coin.png` загрузил как картинку.

Look at result:

![Screenshot2](img/browser_1.png)

## Templating
