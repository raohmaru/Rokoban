package  
{
import flash.system.System;

import jp.raohmaru.game.events.GameEvent;
import jp.raohmaru.events.*;
import jp.raohmaru.rokoban.*;

import flash.display.*;
import flash.events.*;
import flash.filters.DropShadowFilter;
import flash.net.*;
import flash.text.StyleSheet;

/**
 * Editor de mapas para Rokoban.
 * @author raohmaru
 */
public class MapEditor extends MovieClip 
{	
	private var _game :Rokoban,
				_editor :Sprite,
				_data :XML,
				_map :Array,				_gamemap :Array,
				_current_tile :EditorSprite,
				_objects :Array = [],  // Objetos del juego (jugador, cajas)
				_buttons :Array = [Tile.FLOOR, Tile.WALL, Tile.GOAL, Box.type],
				_mouse_down :Boolean,
				_drag_target :EditorSprite,
				_record :uint;
				
	public static var	TILE_W :uint,
						TILE_H :uint,
						ROWS :uint,
						COLS :uint;
	private const	BORDER :DropShadowFilter = new DropShadowFilter(0, 0, 0xCC0000, 1, 4, 4, 10);	
	
	
	public function MapEditor()
	{
		var loader :URLLoader = new URLLoader();
			loader.load(new URLRequest("rokoban.xml"));
			loader.addEventListener(Event.COMPLETE, loadTileset);
	}
	
	/**
	 * Carga uno por uno los SWF con los gráficos.
	 */
	private function loadTileset(e :Event=null) :void
	{
		if(e) _data = new XML(e.target.data);
		
		var swf :XML = _data.tilesets.swf[Tileset.length];
		var loader :Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadTileset);
			loader.load(new URLRequest(swf));
	}
	
	private function onLoadTileset(e :Event) :void
	{
		Tileset.add(LoaderInfo(e.target).content);
		if(Tileset.length == _data.tilesets.swf.length())
			init();
		else
			loadTileset();
	}

	private function init() :void
	{		
		TILE_W = _data.options.tile_width;		TILE_H = _data.options.tile_height;		ROWS = _data.options.rows;		COLS = _data.options.cols;
		
		// Mapa por defecto
		var xmlmap :XML = <map><![CDATA[
##########
#        #
#        #
#        #
#   @    #
#        #
#   $    #
#        #
#   .    #
##########
		]]></map>;
		_editor = new Sprite();
		addChild(_editor);
		createMap(xmlmap);
		
		// Botones de tiles y cajas
		var t :String,
			mc :EditorSprite,
			c :int,
			f :int;
		for(var i:int=0; i<_buttons.length; i++) 
		{
			t = _buttons[i];
			mc = new EditorSprite( t, 0, 0, botHandler );	
			mc.x = 412 + (TILE_W+15)*c;
			mc.y = 30 + 85* f;
			addChildAt(mc, 0);
			_buttons[i] = mc;
			
			if(c++ >= 2)
			{
				c = 0;
				f++;
			}
		}
		
		
		// Selector de tilesets
		var style :StyleSheet = new StyleSheet();
			style.setStyle("a:hover", {color:"#CC0000"});
			
		tilesets_mc.tf.styleSheet = style;
		tilesets_mc.tf.autoSize = "left";
		tilesets_mc.tf.addEventListener(TextEvent.LINK, tilesetHandler);
		EventRegister.addEventsListener(tilesets_mc, tilesetHandler, EventType.MOUSE_UP | EventType.ROLL_OUT);
		tilesetHandler();		
		
		
		// Interfaz
		numlevels_tf.text = "/" + _data.map.length();
		map_tf.restrict = "0-9";
		map_tf.addEventListener(KeyboardEvent.KEY_UP, changeMapKeyHandler);
		go_bot.addEventListener(MouseEvent.MOUSE_UP, changeMap);		probar_bot.addEventListener(MouseEvent.MOUSE_UP, testMap);		copy_bot.addEventListener(MouseEvent.MOUSE_UP, saveHandler);
		record_tf.addEventListener(FocusEvent.FOCUS_OUT, recordHandler);
		
		addEventListener(Event.ENTER_FRAME, update);
		
		
		// Pantalla del juego		
		screen_mc.rewind_bot.addEventListener(MouseEvent.MOUSE_UP, gameHandler);
		screen_mc.salir_bot.addEventListener(MouseEvent.MOUSE_UP, gameHandler);		screen_mc.reset_bot.addEventListener(MouseEvent.MOUSE_UP, gameHandler);
		screen_mc.visible = false;
		
		
		// Instancia del juego para probar mapas
		_game = new Rokoban(_data.options.rows, _data.options.cols, _data.options.tile_width, _data.options.tile_height);
		_game.visible = false;
		_game.addEventListener(GameEvent.SCORE_UPDATE, gameHandler);
		addChild(_game);
	}

	
	
	/**
	 * Crea el mapa.
	 */
	private function createMap(xmlmap :XML) :void
	{
		while(_editor.numChildren > 0)
			EditorSprite( _editor.removeChildAt(0) ).kill(true);
		
		var	map :Array = xmlmap.text().split("\r\n"),
			row :String,
			t :String,
			mc :EditorSprite,
			floor_count :int;
			
		// Elimina el 1r y el último elemento porque son líneas en blanco
		map.shift();
		map.pop();
			
		_map = [];
		_objects = [];
		
		for(var i:int=0; i<map.length; i++) 
		{
			row = map[i];
			_map.push([]);
			for(var j:int=0; j<row.length; j++) 
			{
				t = row.charAt(j);
				
				if(t == Box.type || t == Player.type)
				{
					mc = new EditorSprite(t, j, i, tileHandler);
					_objects.push(mc);
					_editor.addChild(mc);
					t = Tile.FLOOR;
				}
				
				mc = new EditorSprite(t, j, i, tileHandler);
				_editor.addChildAt(mc, (t == Tile.WALL ? _editor.numChildren : floor_count++));
				_map[i].push(mc);
			}
		}
		
		updateMapData();
	}

	private function changeTile(mc :EditorSprite) :void
	{
		var t :String = mc.type;
			
		if(t != Box.type && _current_tile)
		{
			// No puede cambiar un tile sobre el que está un objeto
			for(var i:int=0; i<_objects.length; i++)
				if(mc.px == _objects[i].px && mc.py == _objects[i].py)
					return;
			
			// Tampoco se pueden cambiar los extremos
			if(mc.px == 0 || mc.px == COLS-1 || mc.py == 0 || mc.py == ROWS-1)
				return;
			
			mc.copy(_current_tile);
			updateMapData();
		}
	}
	
	private function changeMapKeyHandler(e :KeyboardEvent) :void
	{
		if(e.keyCode == 13) // Enter key
		{
			changeMap();
			stage.focus = null;  // Remove focus
		}
	}
	
	private function changeMap(e :MouseEvent=null) :void
	{
		var n :int = Math.max( Math.min(int(map_tf.text)-1, _data.map.length()-1), 0);
		
		Tileset.current = _data.map[n].@tileset;
		tilesetHandler();
		
		_record = _data.map[n].@record;
		record_tf.text = _record.toString(10);
		
		// Actualiza el aspecto de los botones por si se ha cambiado de tileset
		for(var i:int=0; i<_buttons.length; i++) 
			EditorSprite(_buttons[i]).updateGraphic();
			
		createMap(_data.map[n]);
	}
	
	/**
	 * Actualiza el movieclip interno de todos los EditorSprite.
	 */
	private function changeTileset(n :uint) :void
	{
		if(n == Tileset.current) return;
		
		Tileset.current = n;
		
		var row :Array;		
		for(var i:int=0; i<_map.length; i++) 
		{
			row = _map[i];
			for(var j:int=0; j<row.length; j++)
				EditorSprite(row[j]).updateGraphic();
		}
		
		for(i=0; i<_objects.length; i++) 
			EditorSprite(_objects[i]).updateGraphic();
			
		for(i=0; i<_buttons.length; i++) 
			EditorSprite(_buttons[i]).updateGraphic();
			
		updateMapData();
	}
	
	/**
	 * Actualiza la matriz del mapa con los nuevos datos y situa los tiles en su correcta profundidad.
	 */
	private function updateMapData() :void
	{
		_gamemap = [];
		var s :String = "",
			mc :EditorSprite,
			row :Array,
			floor_count :int;
		
		// Convierte el mapa en una cadena
		for(var i:int=0; i<_map.length; i++) 
		{
			row = _map[i];
			_gamemap.push([""]);
			for(var j:int=0; j<row.length; j++)
			{
				mc = row[j];
				_gamemap[i] += mc.type;
				_editor.setChildIndex(mc, (mc.type == Tile.WALL ? _editor.numChildren-1 :  floor_count++));
			}
		}
		
		// Añade los objetos
		var tile :EditorSprite,
			len :int;
		for(i=0; i<_objects.length; i++) 
		{
			mc = _objects[i];
			s = _gamemap[mc.py];
			_gamemap[mc.py] = s.substring(0, mc.px) + mc.type + s.substring(mc.px+1);
				
			
			// Profundidad del sprite
			row = _map[mc.py];
			tile = null;
			j = 0;
			len = row.length;
			while( ++j < len )
			{
				tile = row[j];
				if(tile.type == Tile.WALL)
				{
					// Obtiene la primera pared a la derecha del sprite
					if(tile.px > mc.px)
						break;
				}
			}			
			if(tile)
				_editor.setChildIndex(mc, _editor.getChildIndex(tile)-1);
		}
		
		mapdata_tf.text = _gamemap.join("\n");
	}

	private function testMap(e :MouseEvent) :void
	{		
		_game.addMap(_gamemap, Tileset.current);
		_game.currentLevel = _game.numLevels - 1;
		_game.start();
		_game.visible = true;
		screen_mc.visible = true;
		screen_mc.record_tf.text = _record;
		gameHandler();
	}
	

	
	private function update(e :Event) :void
	{
		// Mueve el sprite seleccionado
		if(_drag_target)
		{
			var x :int = (mouseX*(ROWS)) / (ROWS*TILE_W),				y :int = (mouseY*(COLS)) / (COLS*TILE_H);
				
			if(x > 0 && x < COLS-1 && y > 0 && y < ROWS-1)
			{
				var mc :EditorSprite;
				
				// No puede colocarse encima de un objeto
				for(var i:int=0; i<_objects.length; i++)
				{
					mc = _objects[i];
					if(mc != _drag_target && x == mc.px && y == mc.py)
						return;
				}
				
				if(!_map[y][x].walkable) return;
				
				_drag_target.x = x * TILE_W;
				_drag_target.y = y * TILE_H;
				_drag_target.tx = x;				_drag_target.ty = y;
				_drag_target.alpha = 1;
			}
			
			// Si se arrasta una caja fuera del mapa se puede borrar
			else if(_drag_target.type != Player.type)
			{
				_drag_target.x = mouseX - TILE_W/2;				_drag_target.y = mouseY - TILE_H/2;
				_drag_target.alpha = .3;
			}
		}
	}
	
	private function tileHandler(e :MouseEvent) :void
	{
		var mc :EditorSprite = e.target as EditorSprite;
		
		if(e.type == MouseEvent.MOUSE_DOWN)
		{
			// Si se clica sobre un personaje o caja
			if(mc.type == Box.type || mc.type == Player.type)
			{
				_drag_target = mc;
				_drag_target.filters = [BORDER];
				_editor.setChildIndex(_drag_target, _editor.numChildren-1);
			}			
			// Se clica sobre un tile
			else
				changeTile(mc);
			
			_mouse_down = true;
		}
		else if(e.type == MouseEvent.MOUSE_UP)
		{
			// Cuando deja de arrastar un sprite
			if(_drag_target)
			{
				// Actualiza su posición
				if(_drag_target.alpha == 1)
				{
					_drag_target.px = _drag_target.tx;
					_drag_target.py = _drag_target.ty;
					_drag_target.filters = [];
					
					// Si es una caja nueva la añade a la lista
					if(_objects.indexOf(_drag_target) == -1 )
						_objects.push(_drag_target);
					
				}
				// o lo elimina
				else
				{
					var i :int = _objects.indexOf(_drag_target);
					if(i != -1) _objects.splice(i, 1);
					_editor.removeChild(_drag_target);
					_drag_target.kill(true);
				}
				
				updateMapData();
			}
			
			_mouse_down = false;
			_drag_target = null;
		}
		else if(e.type == MouseEvent.MOUSE_OVER)
		{
			if(_mouse_down && !_drag_target) changeTile(mc);
		}
	}
	
	private function botHandler(e :MouseEvent) :void
	{
		if(_current_tile == e.target) return;
		var t :String = e.target.type;
		
		if(e.type == MouseEvent.MOUSE_DOWN)
		{
			// Si se clica sobre la caja
			if(t == Box.type)
			{
				var mc :EditorSprite = new EditorSprite(t, 0, 0, tileHandler);
				_editor.addChild(mc);
				_drag_target = mc;
				_drag_target.filters = [BORDER];
			}
		}
		else if(e.type == MouseEvent.MOUSE_UP)
		{
			// Cambia el tile con el que se "pintará" el mapa
			if(t != Box.type)
			{
				if(_current_tile)
				{
					var temp :EditorSprite = _current_tile;
					_current_tile = null;
					temp.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
				}
				_current_tile = e.target as EditorSprite;
			}
		}
		else
		{
			e.target.filters = (e.type == MouseEvent.MOUSE_OVER) ? [BORDER] : [];
		}
	}

	private function tilesetHandler(e :Event = null) :void
	{
		// Actualiza o el cursor sale del desplegable abierto
		if(!e || e.type == MouseEvent.ROLL_OUT)
		{
			tilesets_mc.tf.text = _data.tilesets.swf[Tileset.current].text().match(/(\w+\.swf)$/)[1];
		}
		// Se clica sobre el desplegable
		else if(e.type == MouseEvent.MOUSE_UP && !tilesets_mc.mouseChildren)
		{
			var s :String = _data.tilesets.swf[Tileset.current].text().match(/(\w+\.swf)$/)[1] + "<br><br>";
			for(var i:int=0; i<_data.tilesets.swf.length(); i++) 
				s += "<a href='event:"+i+"'>" + _data.tilesets.swf[i].text().match(/(\w+\.swf)$/)[1] + "</a><br>";
				
			tilesets_mc.tf.htmlText = s;
		}
		// Se clica sobre una opción (un enlace de texto)
		else if(e.type == TextEvent.LINK)
		{
			changeTileset( uint(TextEvent(e).text) );
		}
		
		tilesets_mc.mouseChildren = (e && e.type == MouseEvent.MOUSE_UP);
		tilesets_mc.back_mc.height = (e && e.type == MouseEvent.MOUSE_UP) ? tilesets_mc.tf.textHeight + 1 : 13;		tilesets_mc.arrow_mc.scaleY = (e && e.type == MouseEvent.MOUSE_UP) ? -1 : 1;
	}

	private function gameHandler(e :Event = null) :void
	{
		if(!e || e.type == GameEvent.SCORE_UPDATE)
		{
			screen_mc.movs_tf.text	 = (e) ? _game.movs : 0;
			screen_mc.targets_tf.text = (e ? _game.targets : 0) + "/" + _game.numTargets;
		}
		else if(e.type == MouseEvent.MOUSE_UP)
		{
			if(e.target.name == "rewind_bot")
				_game.rewind();
				
			else if(e.target.name == "reset_bot")
				_game.reset();
				
			else
			{
				_game.end();
				_game.visible = false;
				screen_mc.visible = false;
				// Si se consigue un récord mejor se actualiza
				if( _game.targets == _game.numTargets && _game.movs < _record)
				{
					_record = _game.movs;
					record_tf.text = _record.toString(10);
				}
			}
		}
	}

	private function recordHandler(e :FocusEvent) :void
	{
		_record = uint(record_tf.text);
	}
	
	private function saveHandler(e :MouseEvent) :void
	{
		// Copia el XML del mapa en el portapapeles del sistema
		if(e.target.name == "copy_bot")
		{
			var s :String = '<map';			
				if(Tileset.current != 0)
				s += ' tileset="' + Tileset.current + '"';				s += ' record="'+_record+'"><![CDATA[\n';			
				s += _gamemap.join("\n");
				s += '\n]]></map>';
			
			System.setClipboard(s);
		}
	}
}
}


import jp.raohmaru.events.*;
import jp.raohmaru.rokoban.*;

import flash.display.*;

/**
 * Representa un sprite del mapa.
 */
class EditorSprite extends Sprite
{
	public var	px :int,
				py :int,
				tx :int,
				ty :int,
				type :String,
				walkable :Boolean,
				movie :MovieClip,
				callback :Function;
	
	public function EditorSprite(type :String, px :int, py :int, callback :Function)
	{	
		if(type == Box.type)
			this.name = Box.className;
		else if(type == Player.type)
			this.name = Player.className;
		else
			this.name = Tile.TILE[type].className;
		
		x = px * MapEditor.TILE_W;
		y = py * MapEditor.TILE_H;
		
		this.px = px;				this.py = py;				this.type = type;
		if(Tile.TILE[type])
			this.walkable = Tile.TILE[type].walkable;
		this.callback = callback;
		
		updateGraphic();		
		EventRegister.addEventsListener(this, callback, EventGroup.BUTTON_EVENTS);
	}
	
	/**
	 * Copia las propiedades del objeto.
	 */
	public function copy(sp :EditorSprite) :void
	{
		name = sp.name;
		type = sp.type;
		walkable = sp.walkable;
		updateGraphic();
	}
	
	public function updateGraphic() :void
	{
		kill();
		
		var ClassRef :Class = Tileset.getClass(name);
		movie = new ClassRef();
		movie.stop();
		addChild(movie);
	}
	
	public function kill(remove :Boolean=false) :void
	{
		if(movie)
		{
			movie.stop();
			removeChild(movie);
			movie = null;
		}
		
		if(remove)
		{
			EventRegister.removeEventsListener(this, callback, EventGroup.BUTTON_EVENTS);
			callback = null;
		}
	}
}