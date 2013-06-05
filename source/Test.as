package  
{
import jp.raohmaru.rokoban.Tileset;
import jp.raohmaru.game.events.GameEvent;
import jp.raohmaru.rokoban.Rokoban;

import flash.display.*;
import flash.events.*;
import flash.net.*;

import jp.raohmaru.rokoban.Map;

/**
 * @author raohmaru
 */
public class Test extends MovieClip 
{
	private var _game :Rokoban,
				_data :XML;
	
	
	
	public function Test()
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
		_game = new Rokoban(_data.options.rows, _data.options.cols, _data.options.tile_width, _data.options.tile_height);
		
		var map :Array;
		for each (var xmlmap :XML in _data.map)
		{
			map = xmlmap.text().split("\r\n");
			// Elimina el 1r y el último elemento porque son líneas en blanco
			map.shift();			map.pop();
			
			_game.addMap(map, xmlmap.@tileset, xmlmap.@record);
		}
		
		addChildAt(_game, 0);
		_game.addEventListener(GameEvent.SCORE_UPDATE, updateScore);		_game.addEventListener(GameEvent.LEVEL_COMPLETE, nextLevel);		_game.addEventListener(GameEvent.GAME_END, gameEnd);
		_game.start();
			
		updateLevel();
		updateScore();
		
		score_mc.rewind_bot.addEventListener(MouseEvent.MOUSE_UP, rewind);
		score_mc.reset_bot.addEventListener(MouseEvent.MOUSE_UP, reset);
		score_mc.newlevel_tf.restrict = "0-9";		score_mc.newlevel_tf.addEventListener(KeyboardEvent.KEY_UP, changeLevelKeyHandler);		score_mc.go_bot.addEventListener(MouseEvent.MOUSE_UP, changeLevel);
	}



	private function rewind(e :MouseEvent) :void
	{
		_game.rewind();
	}
	
	private function reset(e :MouseEvent) :void
	{
		_game.reset();
	}
	
	private function changeLevelKeyHandler(e :KeyboardEvent) :void
	{
		if(e.keyCode == 13) // Enter key
		{
			changeLevel();
			stage.focus = null;  // Remove focus
		}
	}
	
	private function changeLevel(e :MouseEvent=null) :void
	{
		_game.currentLevel = score_mc.newlevel_tf.text-1;
	}
	
	private function updateScore(e :GameEvent=null) :void
	{
		score_mc.movs_tf.text	 = (e) ? _game.movs : 0;
		score_mc.targets_tf.text = (e ? _game.targets : 0) + "/" + _game.numTargets;
	}
	
	private function updateLevel() :void
	{
		score_mc.level_tf.text = _game.currentLevel+1 + "/" + _game.numLevels;		score_mc.record_tf.text = _game.currentMap.record;
	}

	private function nextLevel(e :GameEvent) :void
	{
		_game.nextMap();
		updateScore();
		updateLevel();
	}
	
	private function gameEnd(e :GameEvent) :void
	{
		trace("Fin de juego");
	}
}
}