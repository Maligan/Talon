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

	![Screenshot1](img/browser_1.png)

	Awesome! You did it!

## How browser works

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
2. Stylesheet `style.css`

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

3. And this carefully picked up coin image `coin.png`

	![coin](img/coin.png)

Each of files will be loaded and processed according to theirs content. From `button.xml` will be created new template — *Button*, styles from `style.css` will be merged to global style scope and `coin.png` will be loaded as picture.

Look at result:

![Screenshot2](img/browser_1.png)

## Templating
Основное приемущество шаблонов в том что при [правильном](https://en.wikipedia.org/wiki/Code_reuse#Criticism) использовании они могут значительно упростить приложение, а значит увеличить скорость разработки и что самое, на мой взгляд важное - сохранить нервы разработчиков.

В TML есть два способа указать на переиспользования шаблона - *полный* и *упрощёный*, здесь мы с вами рассмотрим только *упрощёный* метод.

## Import layouts into apps

Если вы не ставите себе цель только создания мокапов, то вам когда-нибудь понадобится перенести ваши наработки в игру. Есть много путей сделать это, но давайте рассмотрим самый быстрый:

1. Упакуйте папку вашего проекта в zip архив выполнив `File -> Publish` или нажав <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>
2. Поместите архив в директорию с ассетами вашей игры и включите файл в сборку через мета-тег `[Embed]`
3. Для примера возьмём тривиальное Starling приложение из раздела [First Steps: Create your Game](http://gamua.com/starling/first-steps/) и дополним его необходимым кодом

```actionscript
import starling.display.Sprite;

import talon.utils.TMLFactoryStarling;

public class Game extends Sprite
{
	private var _factory:TMLFactoryStarling;
	private var _menu:TalonSprite;

    public function Game()
    {
		_factory = new TMLFactoryStarling();

		// ... initialize factory with resources

		_menu = _factory.createElement("Menu");
		_menu.node.bounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
		_menu.node.commit();

		addChild(_menu.self);
    }
}
```

Собрите и запустите приложение, при должной сноровке у вас должно получится:

![Screenshot1](img/browser_1.png)

Браво! Разве не этого мы и добивались?

## What's next?
After this introduction article I recommend you checkout detailed [documentation](./index.md). For quick explore talon's features you can read next part of documentation first:
* [Background](./background.md) — main way to display pictures
* [Layouts](./layouts.md) — how to position elements respect each other and free parent space
* [CSS Dialect](./css.md) — list of **all** attributes implemented within talon
