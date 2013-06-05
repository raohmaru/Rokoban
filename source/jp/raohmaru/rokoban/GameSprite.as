package jp.raohmaru.rokoban
{
import flash.display.MovieClip;

/**
 * Sprite básico de visualización.
 * @author raohmaru
 */
public class GameSprite
{	
	public var		px :int,
					py :int;
	protected var	_sx :int,
					_sy :int,
					_movie :MovieClip,
					_class_name :String,
					_game :Rokoban;
	
	public function get movie() :MovieClip
	{
		return _movie;
	}
	
	
	
	/**
	 * Crea una nueva instancia con un movieclip asociado, que corresponde a un nombre de clase del tileset actual.
	 */
	public function GameSprite(game :Rokoban, name :String, px :int, py :int)
	{
		_game = game;
		_sx = px;
		_sy = py;
				
		updateGraphic(name);
		teleport(px, py);
	}
	
	/**
	 * Establece o cambia el gráfico asociado al objeto.
	 */
	public function updateGraphic(class_name :String=null) :void
	{
		if(!class_name) class_name = _class_name;
		_class_name = class_name;
		
		var ClassReference :Class = Tileset.getClass(_class_name);
		if(ClassReference != null)
		{
			var new_movie :MovieClip = new ClassReference();
			if(_movie)
			{
				new_movie.x = _movie.x;				new_movie.y = _movie.y;
				
				_movie.stop();
				_movie = null;
			}
			
			_movie = new_movie;			
		}
	}
	
	/**
	 * Coloca el sprite en las coordenadas px y py.
	 */
	public function teleport(px :int, py :int) :void
	{
		if( !checkPos(px, py) )
			return;
		
		this.px = px;
		this.py = py;
		
		_movie.x = px * Rokoban.TILE_W;
		_movie.y = py * Rokoban.TILE_H;
	}
	
	/**
	 * Situa el sprite en su posición de inicio. También puede establecer una nueva posición de inicio.
	 */
	public function reset(px :int=-1, py :int=-1) :void
	{
		if(checkPos(px, 0)) _sx = px;		if(checkPos(0, py)) _sy = py;
		
		teleport(_sx, _sy);
	}
	
	/**
	 * Comprueba que la posición esté dentro de los límites del mapa.
	 */
	public function checkPos(px :int, py :int) :Boolean
	{
		return (px >= 0 && px < Rokoban.ROWS && py >= 0 && py < Rokoban.COLS);
	}
	
	/**
	 * Detiene y elimina el movieclip interno.
	 */
	public function kill() :void
	{
		_game = null;
		
		if(_movie)
		{
			_movie.stop();
			_movie = null;
		}
	}
}
}