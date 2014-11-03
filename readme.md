# Talon
## Table of Content
* <a href = "#overview">Overview</a>
* <a href = "#first-steps">First Steps</a>
* <a href = "#editor">Editor</a>
* <a href = "#feature-list">Feature List</a>
* <a href = "#under-the-hood">Under the Hood</a>
* <a href = "#download">Download</a>

## Overview
Talon — библиотека для создания резиновых интерфейсов на <a href="http://gamua.com/starling/">Starling</a>. Данная библиотека - не набор виждетов (т.е. в ней нет классов Кнопка, Список, Всплывающая подсказка и других), билиотека только предоставляет возможность для создания дерева иерархии объектов и адаптациию этого дерева под различные размеры экрана/окна.
## First Steps
Самый простой способ создать элемент интерфейса - создать его из готовой библиотеки (созданной с помощью <a href="editor">редактора</a>)

`
var factory:TalonFactory = TalonFactory.fromArchive(bytes, onComplete);
factory.addEventListener(Event.COMPLETE, onComplete);
function onComplete(e:Event):void
{
	var message:DisplayObject = builder.createElement("MessageBox");
	addChild(message);
}
`
Самый простой способ создать элемент - в ручную
`
// Создатим элемент
var button:TalonComponent = new TalonComponent();
button.node.attributes.parce("100px");
button.node.attributes.parce("100px");
button.node.attributes.backgroundColor = "0xFFFFFF";
// Зададим размеры
button.node.layout.bounds.setTo(0, 0, 100, 100);
button.node.layout.commit();
// Добавим в список отображения
addChild(button);
`

Не слишком просто для создания простой белой коробки не правда ли? Всё из-за того что Talon задуман не для имеративного определения, проще говоря не стоит создавать объекты и выставлять их аттрибуты свойствами языка. Альтернативный вариант — использовать xml - систаксис:

`
var button:TalonComponent = new TalonComponent();
var xml:XML = <node width="100px" heiht="100px" backgroundColor="0xFFFFFF" />
for each (var attribute:XML in xml.attributes())
{
	var name:String = attribute.name();
	var value:String = attribute.valueOf();
	button.node.attributes[name] = value;
}
`

## Editor

## Feature List
Единицы измерения:
- auto
- px
- pt
- em
- %
- *

Базовые шаблоны размещения:
* transfrom (по-умолчанию)
	* x
	* y
	* rotation
	* pivotX, pivotY
	* scaleX, scaleY
* stack
	+ orientation
	+ halign
	+ valign
	+ gap
* anchor
	* top
	* right
	* bottom
	* left
* flow
	+ orintation
	+ gap

## Under the Hood
* За размер и положение объекста отвечает его непосредственный родитель (и только он)
* auto -> %, * недопустимо (или делать проброс к родительскии размерам?)

## Download
* <a href="https://github.com/Maligan/Starling-Extension-Talon">Talon on GitHub</a>
* TalonEditor on GitHub
