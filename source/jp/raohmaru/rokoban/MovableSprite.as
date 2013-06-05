package jp.raohmaru.rokoban
{
	
/**
 * Sprite que se puede mover.
 * @author raohmaru
 */
public class MovableSprite extends GameSprite 
{
	protected var	_moving :Boolean,
					_tx :int,
					_ty :int,
					_t :int,
					_dur :int = 4,
					_vx :Number,
					_vy :Number;
	
	public function get moving() :Boolean
	{
		return _moving;
	}
	
	
	
	public function MovableSprite(game :Rokoban, name :String, px :int, py :int)
	{
		super(game, name, px, py);
	}

	/**
	 * Mueve el sprite a las coordenadas px y py.
	 */
	public function move(px :int, py :int, rewind :Boolean=false) :void
	{
		if(_moving && !rewind) return;
		if( !checkPos(px, py) ) return;
		
		_tx = px;
		_ty = py;
		_vx = (px-this.px)*Rokoban.TILE_W / _dur;
		_vy = (py-this.py)*Rokoban.TILE_H /_dur;
		_t = 0;
		_moving = true;
	}
	
	
	/**
	 * Detiene el movimiento en curso del sprite. 
	 */
	public function stop() :void
	{
		movie.stop();
		// Si se está moviendo lo detiene en la celda de destino
		teleport( (_moving ? _tx : px), (_moving ? _ty : py) );
		_moving = false;
	}

	override public function teleport(px :int, py :int) :void
	{
		super.teleport(px, py);
		
		if( checkPos(px, py) )		
			_game.setSpriteDepth(this);
	}
	
	override public function reset(x :int=-1, y :int=-1) :void
	{
		super.reset(x, y);
		_moving = false;
	}
	
	/**
	 * Anima el elemento mientras se mueve. Invocado desde Rokoban para sincronizar todos los elementos.
	 */
	public function update() :void
	{
		if(_moving)
		{
			if(_t++ < _dur)
			{
				_movie.x += _vx;
				_movie.y += _vy;
			}
			else
			{
				_moving = false;
				teleport(_tx, _ty);
			}
		}
	}
}
}