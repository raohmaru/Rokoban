package jp.raohmaru.rokoban
{
import jp.raohmaru.game.enums.Direction;
import jp.raohmaru.game.events.GameEvent;
import jp.raohmaru.game.core.IGame;

import flash.display.*;
import flash.events.*;
import flash.geom.Point;
import flash.ui.Keyboard;

/**
 * Juego estilo Sokoban.
 * @author raohmaru
 */
public class Rokoban extends Sprite implements IGame
{
	internal static var	TILE_W :uint,
						TILE_H :uint,
						ROWS :uint,
						COLS :uint;
	
	private var	_maps :Array = [],
				_curr_map :int,
				_player :Player,
				_dir :Point,
				_keyc :uint,
				_key_pressed :Boolean,
				
				_map :Array,
				_boxes :Array,
				_movs :Array = [],
				_num_targets :uint,  // Objetivos del mapa
				_targets :uint,		 // Objetivos conseguidos
				_running :Boolean;
	/**
	 * Obtiene la cantidad de movimientos realizados.
	 */
	public function get movs() :uint
	{
		return _movs.length;
	}	
	/**
	 * Obtiene el número de objetivos conseguidos.
	 */
	public function get targets() :uint
	{
		return _targets;
	}
	/**
	 * Obtiene el número de objetivos del mapa.
	 */
	public function get numTargets() :uint
	{
		return _num_targets;
	}
	public function get numLevels() :uint
	{
		return _maps.length;
	}
	
	public function get currentLevel() :uint
	{
		return _curr_map;
	}
	public function set currentLevel(value :uint) :void
	{
		_curr_map = Math.max( Math.min(value, _maps.length-1), 0 );
		
		// Si está en medio de un nivel lo da por finalizado
		if(_running)
		{
			_curr_map--;  // Disminuye un nivel pq en nextMap() lo aumenta
			mapComplete();
		}
	}
	
	public function get currentMap() :Map
	{
		return _maps[_curr_map];
	}
	
	
	
	public function Rokoban(rows :uint=10, cols:uint=10, tile_w :uint=40, tile_h :uint=40)
	{
		ROWS = rows;
		COLS = cols;
		TILE_W = tile_w;		TILE_H = tile_h;
	}

	/**
	 * Añade un nuevo mapa.
	 */
	public function addMap(map :Array, tileset_id :uint, record :uint=0) :void
	{
		_maps.push( new Map(map, tileset_id, record) );
	}
	
	/**
	 * Parsea y crea un mapa a partir de una cadena.
	 */
	private function createMap() :void
	{
		// Limpia la pantalla
		while(numChildren > 0)
			removeChildAt(0);
		
		// Se asegura de limpiar correctamente
		if(_map)
		{
			var	i :int = _map.length,
				j :int;
			while( --i > -1 )
			{
				j = _map[i].length;
				while( --j > -1 )
					GameSprite(_map[i][j]).kill();
			}
			i = _boxes.length;
			while( --i > -1 )
				GameSprite(_boxes[i]).kill();
		}
		
		_map = [];		_boxes = [];
		
		
		var	map :Map = _maps[_curr_map],
			rows :Array = map.data,
			row :String,
			t :String,
			tile :Tile,
			box :Box,
			floor_count :int;
			
		Tileset.current = map.tilesetID;
		_num_targets = map.numTargets;
		
		for(i=0; i<rows.length; i++) 
		{
			row = rows[i];
			_map.push([]);
			for(j=0; j<row.length; j++) 
			{
				t = row.charAt(j);
				
				// Añade una caja
				if(t == Box.type)
				{
					box = new Box(this, j, i);
					addChild(box.movie);
					_boxes.push(box);					
					t = Tile.FLOOR;  // En la posición de la caja situa un tile traspasable
				}
				// Posición de inicio del jugador
				else if(t == Player.type)
				{
					_player.updateGraphic();
					_player.reset(j, i);
					_player.facing = Direction.DOWN;
					addChild(_player.movie);
					t = Tile.FLOOR;  // Situa un tile traspasable				
				}
				
				// Añade un tile		
				tile = new Tile(this, t, j, i);
				// Las paredes las pone en el nivel superior; el resto al fondo
				addChildAt(tile.movie, (t == Tile.WALL ? numChildren :  floor_count++)  );
				_map[i].push(tile);
			}
		}
	}
	
	/**
	 * Comienza el juego.
	 */
	public function start() :void
	{
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyHandler);
		addEventListener(Event.ENTER_FRAME, update);
		
		// Se asegura que al menos haya un tileset para los gráficos
		if(Tileset.length == 0) Tileset.add(parent);
				
		if(!_player) _player = new Player(this, 0, 0);
		
		_curr_map--;  // Disminuye un nivel pq en nextMap() lo aumenta
		nextMap();
	}
	
	/**
	 * Detiene el juego.
	 */
	public function end() :void
	{		
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		stage.removeEventListener(KeyboardEvent.KEY_UP, keyHandler);
		removeEventListener(Event.ENTER_FRAME, update);
		
		_running = false;
		_player.stop();
	}
	
	/**
	 * Retrocede en el tiempo y mueve los sprites a sus posiciones anteriores.
	 */
	public function rewind() :void
	{
		if(!_running) return;
		
		if(_movs.length > 0)
		{
			var state :Array = _movs.pop(),
				i :int = state.length;
			
			while( --i > -1 )		
				MovableSprite(state[i][0]).move( state[i][1], state[i][2], true );
			
			dispatchEvent(new GameEvent(GameEvent.SCORE_UPDATE, this));
		}
	}
	
	/**
	 * Reseta las posiciones del jugador y de las cajas.
	 */
	public function reset() :void
	{
		// Si no se ha iniciado el juego no hay nada que resetear
		if(!_map) return;
		
		_running = true;
		_movs = [];
		_targets = 0;
		
		_player.reset();
		
		var	i:int = _boxes.length;
		while( --i > -1 )
			Box(_boxes[i]).reset();
			
		dispatchEvent(new GameEvent(GameEvent.SCORE_UPDATE, this));
	}
	
	public function nextMap() :void
	{
		// Se asegura que no se haya detenido el juego y que exista el mapa siguiente
		if(hasEventListener(Event.ENTER_FRAME) && _curr_map < _maps.length-1)
		{
			// Resetea los valores para el nuevo mapa
			_running = true;
			_movs = [];
			_num_targets = 0;
			_targets = 0;
		
			_curr_map++;
			createMap();
		}
	}

	
	
	/**
	 * Comprueba si la tile es traspasable.
	 */
	private function isWalkable(tx :uint, ty :uint, pushing :Boolean) :Boolean
	{
		// Ojo que primero se obtiene la fila (y) y luego la columna (x)
		var tile :Tile = _map[ty][tx];
		// Si está fuera de los límites del mapa caput		
		if(!tile) return false;
		
		var walkable :Boolean = tile.walkable;
			
		// Si es traspasable pero arrastra una caja
		if(walkable && pushing)
		{
			var	box :Box,
				i:int = _boxes.length;
			while( --i > -1 )
			{
				box = _boxes[i];
				// Si hay otra caja en medio no se puede pasar a esa tile
				if(box.px == tx && box.py == ty)
					return false;
			}
		}
		
		return walkable;
	}
	
	/**
	 * Comprueba los objetivos conseguidos.
	 */
	private function checkTargets() :void
	{
		var targets :uint,
			box :Box,
			i:int = _boxes.length;
		while( --i > -1 )
		{
			box = _boxes[i];
			// Si la caja está en la posición de destino
			if(Tile(_map[box.py][box.px]).type == Tile.GOAL)
				targets++;
		}
		
		if(targets != _targets)
		{
			_targets = targets;
			dispatchEvent(new GameEvent(GameEvent.SCORE_UPDATE, this));
			if(_targets == _num_targets) mapComplete();
		}
	}
	
	private function mapComplete() :void
	{
		_running = false;
		_player.stop();
		
		if(_curr_map < _maps.length-1)
			dispatchEvent(new GameEvent(GameEvent.LEVEL_COMPLETE, this));
		else
			dispatchEvent(new GameEvent(GameEvent.GAME_END, this));
	}
	
	/**
	 * Establece la correcta profundidad del sprite al moverse por el mapa (por debajo de la pared a su derecha inmediata y de
	 * otros sprites que estén más abajo y a la derecha).
	 * Cuando un MovableSprite se mueve invoca este método.
	 */
	internal function setSpriteDepth(ms :MovableSprite) :void
	{		
		if(!_map || !contains(ms.movie)) return;
		
		// Obtiene la profundidad de la pared a la derecha del sprite
		var row :Array = _map[ms.py],
			tile :Tile,
			len :int = row.length,
			i:int,
			d :int;
		while( ++i < len )
		{
			tile = row[i];
			if(tile.type == Tile.WALL && tile.px > ms.px)
			{
				d = getChildIndex(tile.movie);
				break;
			}
		}		
			
		// Obtiene la profundidad de la jugador si está en la misma fila y a su derecha
		if(ms != _player && ms.py == _player.py && ms.px < _player.px)
			d = Math.min( d, getChildIndex(_player.movie) );
		
		// Ídem con las cajas
		var box :Box;
		i = _boxes.length;
		while( --i > -1 )
		{
			box = _boxes[i];
			if(ms != box && ms.py == box.py && ms.px < box.px)
				d = Math.min( d, getChildIndex(box.movie) );
		}
		
		// Si se cambia de una profundidad menor a una mayor el sprite se sitúa por encima del sprite en ese nivel.
		// (Si es al revés -de mayor a menor- se situa debajo)
		// Restamos 1 para ponerlo debajo.
		if(d > 0)
		{
			if(d > getChildIndex(ms.movie)) d -= 1;
			setChildIndex(ms.movie, d);
		}
	}
	
	
	
	private function update(e :Event) :void
	{
		if(_dir)
		{			
			// Obtiene el tile de destino
			var p :Point = new Point(_player.px+_dir.x, _player.py+_dir.y),
				t :Point = p;
			
			// Comprueba si hay una caja en la tile de destino
			var	box :Box,
				box_p :Point,
				i:int = _boxes.length;
			while( --i > -1 )
			{
				box = _boxes[i];
				// Si hay una caja en medio, la tile de destino pasa a ser la adyacente e intenta empujar la caja
				if(box.px == p.x && box.py == p.y)
				{
					if(box.movable)
					{
						box_p = new Point(box.px+_dir.x, box.py+_dir.y);
						t = box_p;
					}
					break;
				}
				box = null;
			}
			
			// Si la tile de destino es traspasable, mueve al jugador
			if( (!box || box.movable) && isWalkable(t.x, t.y, box_p != null) )
			{
				// Almacena los movimientos para poder rebobinar
				var state :Array = [];
					state.push( [_player, _player.px, _player.py] );
				_player.pushing = (box_p != null);
				_player.move(p.x, p.y);
				
				// Empuja la caja
				if(box_p)
				{						
					// Almacena los movientos para poder rebobinar
					state.push( [box, box.px, box.py] );
					box.move(box_p.x, box_p.y);
				}
				
				_movs.push( state );
				dispatchEvent(new GameEvent(GameEvent.SCORE_UPDATE, this));
			}
			// Y si no mueve al jugador lo encara
			else
			{
				_player.pushing = true;
				_player.faceToDirection(_dir.x, _dir.y);
				_player.move(_player.px, _player.py);
			}
		
			_dir = null;
		}
		
		
		if(_running)
		{
			checkTargets();
			
			// Actualiza y mueve todos los elementos del juego
			_player.update();
			i = _boxes.length;
			while( --i > -1 )
				Box(_boxes[i]).update();
		}
	}
	
	private function keyHandler(e :KeyboardEvent) :void
	{
		// Bloquea el teclado si se completado el nivel o si el jugador se está moviendo
		if(!_running || (e.type == KeyboardEvent.KEY_DOWN && _player.moving)) return;
		
		if(e.type == KeyboardEvent.KEY_DOWN)
		{
			// Comprueba que no esté presionada la misma tecla
			if(!_key_pressed || _keyc != e.keyCode)
			{
				_keyc = e.keyCode;
				if(_keyc == Keyboard.UP || _keyc == Keyboard.RIGHT || _keyc == Keyboard.DOWN || _keyc == Keyboard.LEFT)
				{
					_dir = new Point();
					_dir.x = (_keyc == Keyboard.LEFT) ? -1 : (_keyc == Keyboard.RIGHT ? 1 : 0);					_dir.y = (_keyc == Keyboard.UP) ? -1 : (_keyc == Keyboard.DOWN ? 1 : 0);
					
					_key_pressed = true;
				}
				else if(_keyc == 82) // "R"
				{
					rewind();
					_key_pressed = true;
				}				
			}
		}
		else
		{
			// Sólo si se libera la misma tecla
			if(_key_pressed && e.keyCode == _keyc) _key_pressed = false;
		}
	}
}
}