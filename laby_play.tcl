# laby_play.tcl

# initialisation 

proc play_init {canvas} {

    puts "initialize the event interface"
    bind $canvas <ButtonPress-1> {play_ButtonPress %x %y}
    bind $canvas <ButtonRelease-1> {play_ButtonRelease %x %y}
    bind $canvas <Button1-Motion> {play_motion %x %y}
}

# event button1 pressed

proc play_ButtonPress {x y} {

    puts "proc play_ButtonPress $x $y"

}

# event button1 released

proc play_ButtonRelease {x y} {
    
    puts "proc play_ButtonRelease $x $y"
}

# event mouse motion while B1 pressed

proc play_motion {x y} {

    puts "proc play_motion $x $y"
}