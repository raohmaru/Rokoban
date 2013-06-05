package jp.raohmaru.rokoban
{

/**
 * Baldosa o celda (tile) utilizada en el juego.
 * @author raohmaru
 */
public class Tile extends GameSprite
{
	public static const	WALL	:String = "#",
						FLOOR	:String = " ",
						GOAL	:String = ".",
						// Define los tipos de tiles
						TILE :Object = {
							" "	: {className:"floor", walkable:true},
							"."	: {className:"goal",  walkable:true},
							"#"	: {className:"wall",  walkable:false}
						};
											
	public var	type :String,
				walkable :Boolean;
				
				
	
	public function Tile(game :Rokoban, type :String, px :int, py :int)
	{
		super(game, TILE[type].className, px, py);
		
		this.type = type;		this.walkable = TILE[type].walkable;
	}
}
}