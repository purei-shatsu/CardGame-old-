function love.conf(t)
	t.modules.audio = true
	t.modules.graphics = true
	t.modules.image = true
	t.modules.math = true
	t.modules.keyboard = true
	t.modules.joystick = true
	t.modules.mouse = true
	t.modules.sound = true
	t.modules.timer = true
	t.modules.thread = true
	t.console = true
	t.identity = 'Fusion!'
    t.window.title = t.identity
end
