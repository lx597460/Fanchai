package;

import flixel.FlxState;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import states.FreeplayState;
import states.StoryMenuState;
import states.TitleState;
import states.MainMenuState;
#if HSCRIPT_ALLOWED
import sscript.SScript;
#end

/**
 * 按需从 mods/states/<ClassName>.hx 覆盖原版 State。
 * 找不到就返回原 class，玩家/开发者无感。
 */
class ModStateHelper
{
	/** 允许被 mods 覆盖的 State 白名单 */
	public static final OVERRIDABLE:Array<String> = [
		"TitleState",
		"MainMenuState",
		"StoryMenuState",
		"FreeplayState"
	];

	/** 已解析的覆盖缓存，避免每次 switchState 都读盘 */
	private static var cache:Map<String, Class<FlxState>> = new Map();

	/**
	 * 传入原版 State 的 Class，返回应该真正实例化的 Class。
	 * 如果 mods/states 下有同名 .hx，返回 SScript 编译出来的类；否则返回原 class。
	 */
	public static function resolve(original:Class<FlxState>):Class<FlxState>
	{
		#if MOD_STATES_ALLOWED
		var name = Type.getClassName(original);
		if (name == null) return original;
		var short = name.split(".").pop();
		if (!OVERRIDABLE.contains(short)) return original;

		if (cache.exists(short)) return cache.get(short);

		var modPath = Path.join([Mods.directory, "states", short + ".hx"]);
		if (!FileSystem.exists(modPath))
		{
			cache.set(short, original);
			return original;
		}

		try
		{
			var script = new SScript();
			script.doString(File.getContent(modPath));
			var cls = script.get("__class__");
			if (cls != null && Std.isOfType(cls, Class))
			{
				var casted = cast(cls, Class<FlxState>);
				cache.set(short, casted);
				trace('[ModStateHelper] Overrode $short from $modPath');
				return casted;
			}
			else
			{
				trace('[ModStateHelper] $short 没有导出 __class__，使用原版');
			}
		}
		catch (e:Dynamic)
		{
			trace('[ModStateHelper] 加载 $modPath 失败：$e，回退原版');
		}
		#end
		return original;
	}
}