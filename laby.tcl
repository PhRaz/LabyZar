#!/usr/bin/env tclsh

# 	$Id$	

# laby
 
# Auteur: Philippe Razavet <philippe.razavet@gmail.com>

package require Tk

# play functions library

source laby_play.tcl

# The global laby data array.

set laby_data(number) 0

# Laby face names.

set laby_data(face) [list front side top]

# Data for display management.

# Canvas size.

set laby_display(nb_pixel) 600

# Display translation vector for 2D faces.

# DOC Vecteur de translation des faces du cube pour l'affichage.

set laby_display(translation.front) {0 1}
set laby_display(translation.top)   {0 0}
set laby_display(translation.side)  {1 1}

# DOC Vecteurs de changement de repère pour l'affichage des faces du cube.

# Display transformation vector for 2D flat faces.

set laby_display(xy.front) {{1 0} {0 -1}}
set laby_display(xy.side) {{-1 0} {0 -1}}
set laby_display(xy.top) {{1 0} {0 1}}

# Display transformation vector for hexagonale view.

set sin_PI_6 0.5
set cos_PI_6 0.866025403784

set laby_display(xy_h.front) [list [list $cos_PI_6 0] [list $sin_PI_6 -1]]
set laby_display(xy_h.side)  [list [list -$cos_PI_6 0] [list $sin_PI_6 -1]]
set laby_display(xy_h.top)   [list [list $cos_PI_6 -$cos_PI_6] [list $sin_PI_6 $sin_PI_6]]

# Corresponding vectors for 2d points 4 directions.

set laby_data(direction_2d.0) {1 0}
set laby_data(direction_2d.1) {-1 0}
set laby_data(direction_2d.2) {0 1}
set laby_data(direction_2d.3) {0 -1}

# Create a new laby.
#
# Return a laby handler.

proc laby_create {size} {

    global laby_data

    # Name of the new laby (handler).

    set laby_name laby$laby_data(number)
    incr laby_data(number)

    # Number of point in the grid.

    set laby_data($laby_name.size) $size

    # Number of point used is set to 1.

    set laby_data($laby_name.used) 1

    # Start position of the 3D cursor.

    set laby_data($laby_name.cursor.position) {0 0 0}

    # Update the history.

    update_histo $laby_name

    # Initialize data for each 2D face.

    foreach face $laby_data(face) {

	# Number of point used is set to 1.

	set laby_data($laby_name.face.$face.used) 1

	# The cursor position.

	set laby_data($laby_name.face.$face.cursor.position) {0 0}

	# Initialize the grid as a list. 

	# DOC l'ordre des points dans la liste correspond à l'ordre des colonnes
	# en y sur l'axe x.

	for {set x 0} {$x < $size} {incr x} {
	    for {set y 0} {$y < $size} {incr y} {	    			
		
		# DOC Un point d'une face du cube est une liste de 4 entiers qui
		# permet de gérer chacune des 4 directions possibles, dans
		# l'ordre suivant x, -x, y, -y.

		lappend laby_data($laby_name.face.$face.grid) \
		    [list \
			 [expr ($x < ($size - 1)) ? 1 : 0] \
			 [expr ($x > 0) ? 1 : 0] \
			 [expr ($y < ($size - 1)) ? 1 : 0] \
			 [expr ($y > 0) ? 1 :0]]
	    }
	}
    }

    # Initialize the 3D labyrinthe.
    
    for {set x 0} {$x < $size} {incr x} {
	for {set y 0} {$y < $size} {incr y} {
	    for {set z 0} {$z < $size} {incr z} {
		
		# DOC Un point du cube est une liste de 6 entier qui permet de
		# gérer chacune des 6 directions possibles, dans l'ordre
		# suivant: x, -x, y, -y, z, -z.
		
		lappend laby_data($laby_name.grid)  \
		    [list \
			 [expr ($x < ($size - 1)) ? 1 : 0] \
			 [expr ($x > 0) ? 1 : 0] \
			 [expr ($y < ($size - 1)) ? 1 : 0] \
			 [expr ($y > 0) ? 1 : 0] \
			 [expr ($z < ($size - 1)) ? 1 : 0] \
			 [expr ($z > 0) ? 1 :0]]
	    }
	}
    }
    
    return $laby_name
}

# Reset laby data.

proc laby_delete {laby} {

    global laby_data
    global laby_display

    array unset laby_data $laby.*
    array unset laby_display $laby.*

    $laby_display(canvas) delete all
}

# Move the cursor on the given 2D direction.

proc move_2d {laby face direction} {

    global laby_data    
    global laby_display

    # Update the display data.

    set x [lindex $laby_data($laby.face.$face.cursor.position) 0]
    set y [lindex $laby_data($laby.face.$face.cursor.position) 1]
    
    # Get current start point from the grid.

    set index_start [get_index_from_cursor_2d $laby $face]

    for {set i 0} {$i < 2} {incr i} {
	
	# Make the start to end direction value.
	
	if {[lindex $direction $i] != 0} {
	    
	    if {[lindex $direction $i] == 1} {
		
		lappend move_start_to_end 1 0
		lappend move_end_to_start 0 1
		
	    } else {	   

		lappend move_start_to_end 0 1
		lappend move_end_to_start 1 0
	    }

	} else {
	    
	    lappend move_start_to_end 0 0
	    lappend move_end_to_start 0 0
	}	
    }
    
    # Update counter if the next point to move on, if free.
    
    if {([lsearch [get_point_from_direction_2d $laby $face $move_start_to_end] 2] == -1) \
	    && ([lsearch $move_start_to_end 1] != -1)} {

	incr laby_data($laby.face.$face.used)

    }


    for {set i 0} {$i < 2} {incr i} {
	
	# Update the 2d cursor.
	
	lset laby_data($laby.face.$face.cursor.position) $i \
	    [expr \
		  [lindex $laby_data($laby.face.$face.cursor.position) $i] \
		  + [lindex $direction $i]]
    }

    # Update the display.

    set i [lsearch $move_start_to_end 1]

    if {$i != -1} {
	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.$face.segment.$x.$y.$i) -fill red -width 5
    }

    set x [lindex $laby_data($laby.face.$face.cursor.position) 0]
    set y [lindex $laby_data($laby.face.$face.cursor.position) 1]
    
    set i [lsearch $move_end_to_start 1]

    if {$i != -1} {
	$laby_display(canvas) itemconfigure \
	    $laby_display($laby.$face.segment.$x.$y.$i) -fill red -width 5
    }
    
    # Get the end point from the grid.
    
    set index_end [get_index_from_cursor_2d $laby $face]
    
    # Update the start and end point in the grid.
    
    for {set i 0} { $i < 4} {incr i} {
		
	if {[lindex $move_start_to_end $i] == 1} {
	    lset laby_data($laby.face.$face.grid) $index_start $i 2
	}
	
	if {[lindex $move_end_to_start $i] == 1} {
	    lset laby_data($laby.face.$face.grid) $index_end $i 2
	}
    }

}

# Get the index correspponding to the 2d cursor of the given labyrinthe..

proc get_index_from_cursor_2d {laby face} {
    
    global laby_data

    return [get_index_from_coord_2d $laby $laby_data($laby.face.$face.cursor.position)]
}

# Get the index correspponding to the given 2d coordinates.

proc get_index_from_coord_2d {laby coord} {

    global laby_data

    set size $laby_data($laby.size)

    return [expr \
		[lindex $coord 0] * $size \
		+ [lindex $coord  1]]
}

# Get the current cursor point from the grid.

proc get_point_from_cursor_3d {laby} {
    
    global laby_data

    return [lindex $laby_data($laby.grid) [get_index_from_cursor_3d $laby]]
}

# Get the index correspponding to the 3d cursor of the given labyrinthe..

proc get_index_from_cursor_3d {laby} {
    
    global laby_data

    return [get_index_from_coord_3d $laby $laby_data($laby.cursor.position)]
}

# Get the index corresponding to the given 3d coordinates.

proc get_index_from_coord_3d {laby coord} {
    
    global laby_data

    set size $laby_data($laby.size)

    return [expr \
		[lindex $coord 0] * $size * $size \
		+ [lindex $coord  1] * $size \
		+ [lindex $coord 2]]
}

# Move the cursor on the given 3D direction.
#
# param laby labyrinthe name
# param direction 3D vector

proc move_3d {laby direction} {

    global laby_data
    
    # Get current start point from the grid.

    set index_start [get_index_from_cursor_3d $laby]
    
    for {set i 0} {$i < 3} {incr i} {
	
	# Update the 3D cursor.
	
	lset laby_data($laby.cursor.position) $i \
	    [expr [lindex $laby_data($laby.cursor.position) $i] \
		 + [lindex $direction $i]]

	# Make the start to end value.

	if {[lindex $direction $i] != 0} {
	    
	    if {[lindex $direction $i] == 1} {

		lappend move_start_to_end 1 0
		lappend move_end_to_start 0 1

	    } else {	   

		lappend move_start_to_end 0 1
		lappend move_end_to_start 1 0
	    }
	    
	} else {

	    lappend move_start_to_end 0 0
	    lappend move_end_to_start 0 0
	}
    }
    
    # Get the end point from the grid.    

    set index_end [get_index_from_cursor_3d $laby]
    
    # Update the start and end point in the grid.

    for {set i 0} { $i < 6} {incr i} {

	lset laby_data($laby.grid) $index_start $i \
	    [expr \
		 [lindex $laby_data($laby.grid) $index_start $i] \
		 + [lindex $move_start_to_end $i]]

	lset laby_data($laby.grid) $index_end $i \
	    [expr \
		 [lindex $laby_data($laby.grid) $index_end $i] \
		 + [lindex $move_end_to_start $i]]	
    }	        

    # Update the 2D faces.

    move_2d $laby front [list [lindex $direction 0] [lindex $direction 1]]
    move_2d $laby side [list [lindex $direction 2] [lindex $direction 1]]
    move_2d $laby top [list [lindex $direction 0] [lindex $direction 2]]

    # Counter.
    
    incr laby_data($laby.used)

    # Update the history

    update_histo $laby   
}

# Move back. Go to the previous step in movement history and update
# the display color.
#
# param laby labyrinthe id

proc move_back_3d {laby} {

    global laby_data
    global laby_display

    set status 0
    
    if {[llength $laby_data($laby.histo)] > 1} {
	
	set status 1

	# Keep the current position.

	set old_position [lindex $laby_data($laby.histo) end]

	set xs [lindex $old_position 0]
	set ys [lindex $old_position 1]
	set zs [lindex $old_position 2]

	# Update the history.

	set laby_data($laby.histo) [lrange $laby_data($laby.histo) 0 end-1]

	# Update the 3D cursors.

	set laby_data($laby.cursor.position) [lindex $laby_data($laby.histo) end]

	# Update the 2D cursors.

	set xe [lindex $laby_data($laby.cursor.position) 0]
	set ye [lindex $laby_data($laby.cursor.position) 1]
	set ze [lindex $laby_data($laby.cursor.position) 2]

	set laby_data($laby.face.front.cursor.position) [list $xe $ye]
	set laby_data($laby.face.side.cursor.position) [list $ze $ye]
	set laby_data($laby.face.top.cursor.position) [list $xe $ze]		

	# x_start x_end y_start y_end i_start_to_end i_end_to_start

	set direction [list [expr $xe > $xs] [expr $xe < $xs] [expr $ye > $ys] [expr $ye < $ys] ]

	set i [lsearch $direction 1]

	if {$i != -1} {

	    $laby_display(canvas) itemconfigure \
		$laby_display($laby.front.segment.$xs.$ys.$i) -fill yellow -width 5

	    set direction [list [expr $xe < $xs] [expr $xe > $xs] [expr $ye < $ys] [expr $ye > $ys]]
	
	    set i [lsearch $direction 1]

	    $laby_display(canvas) itemconfigure \
		$laby_display($laby.front.segment.$xe.$ye.$i) -fill yellow -width 5
	}

	set direction [list [expr $ze > $zs] [expr $ze < $zs] [expr $ye > $ys] [expr $ye < $ys] ]

	set i [lsearch $direction 1]

	if {$i != -1} {
	    
	    $laby_display(canvas) itemconfigure \
		$laby_display($laby.side.segment.$zs.$ys.$i) -fill yellow -width 5
	    
	    set direction [list [expr $ze < $zs] [expr $ze > $zs] [expr $ye < $ys] [expr $ye > $ys] ]

	    set i [lsearch $direction 1]

	    $laby_display(canvas) itemconfigure \
		$laby_display($laby.side.segment.$ze.$ye.$i) -fill yellow -width 5
	}
	
	
	set direction [list [expr $xe > $xs] [expr $xe < $xs] [expr $ze > $zs] [expr $ze < $zs] ]

	set i [lsearch $direction 1]

	if {$i != -1} {
	    
	    $laby_display(canvas) itemconfigure \
		$laby_display($laby.top.segment.$xs.$zs.$i) -fill yellow -width 5

	    set direction [list [expr $xe < $xs] [expr $xe > $xs] [expr $ze < $zs] [expr $ze > $zs] ]

	    set i [lsearch $direction 1]

	    $laby_display(canvas) itemconfigure \
		$laby_display($laby.top.segment.$xe.$ze.$i) -fill yellow -width 5
	}
    }

    return $status
}

proc update_histo {laby} {

    global laby_data

    lappend laby_data($laby.histo) $laby_data($laby.cursor.position)
}

# Display the labyrinthe on a 2D canvas.

proc display {laby {type flat}} {
    
    global laby_data
    global laby_display
    global sin_PI_6
    global cos_PI_6

    set size $laby_data($laby.size)
    set rayon 3
      
    # Compute the graphic unit length, use float (2.0) and round for better
    # centering of the grids.

    set grid_unit [expr round($laby_display(nb_pixel) / ($size * 2.0 + 2))]

    # Compute the display translation vectors.
    
    set middle  [expr $laby_display(nb_pixel) / 2]

    if {$type == "hexa"} {
	
	set laby_display(translation_h.front) [list \
						   [expr $middle - ($size - 1)  * $grid_unit * $cos_PI_6] \
						   [expr $middle + ($size - 1) * $grid_unit *  $sin_PI_6]]

	set laby_display(translation_h.top) [list \
						 $middle \
						 [expr $middle - ($size - 1) * 2 * $grid_unit *  $sin_PI_6]]

	set laby_display(translation_h.side) [list \
						  [expr $middle + ($size - 1) * $grid_unit * $cos_PI_6] \
						  [expr $middle + ($size - 1) * $grid_unit * $sin_PI_6]]

    } else {
	
        set laby_display(translation_h.front) [list \
						   [expr $middle  - $size * $grid_unit] \
						   [expr $middle  + $size * $grid_unit]]
	
	set laby_display(translation_h.top) [list \
						 [expr $middle  - $size * $grid_unit] \
						 [expr $middle  - $size * $grid_unit]]
	
        set laby_display(translation_h.side) [list \
						  [expr $middle  + $size * $grid_unit] \
						  [expr $middle  + $size * $grid_unit]]	
    }
    
    foreach face $laby_data(face) {
	
	# Translation of the face origine in the display coordinates.
	
	set orig $laby_display(translation_h.$face)
	
	set x_orig  [lindex $orig 0]
	set y_orig  [lindex $orig 1]
	
	# Computes the direction and size of base vectors in the display
	# coordinates.
	
	if {$type == "hexa"} {
	    
	    set dir_x [list \
			   [expr [lindex $laby_display(xy_h.$face) 0 0] * $grid_unit] \
			   [expr [lindex $laby_display(xy_h.$face) 0 1] * $grid_unit]]
	    
	    set dir_y [list \
			   [expr [lindex $laby_display(xy_h.$face) 1 0] * $grid_unit] \
			   [expr [lindex $laby_display(xy_h.$face) 1 1] * $grid_unit]]
	} else {
	    
	    set dir_x [list \
			   [expr [lindex $laby_display(xy.$face) 0 0] * $grid_unit] \
			   [expr [lindex $laby_display(xy.$face) 0 1] * $grid_unit]]
	    
	    set dir_y [list \
			   [expr [lindex $laby_display(xy.$face) 1 0] * $grid_unit] \
			   [expr [lindex $laby_display(xy.$face) 1 1] * $grid_unit]]
	}
	
	# Get the face list of point.

	set grid $laby_data($laby.face.$face.grid)

	for {set x 0} {$x < $size} {incr x} {

	    for {set y 0} {$y < $size} {incr y} {

		# Compute the point coordinates by using the xy direction
		# vector.

		set ox [expr $x_orig + $x * [lindex $dir_x 0] + $y * [lindex $dir_x 1]]
		set oy [expr $y_orig + $x * [lindex $dir_y 0] + $y * [lindex $dir_y 1]]
		
		# Draw the segments between 2 points in the grid.

		set index [expr ($x * $size) + $y]
		
		for {set i 0} {$i < 4} {incr i} {
		    
		    set seg_type [lindex $grid $index $i]
		    
		    if {$seg_type == 1} {
			
			set dx [expr \
				    $ox \
				    + [lindex $laby_data(direction_2d.$i) 0] * [lindex $dir_x 0] \
				    + [lindex $laby_data(direction_2d.$i) 1] * [lindex $dir_x 1]]			
			set dy [expr \
				    $oy \
				    + [lindex $laby_data(direction_2d.$i) 0] * [lindex $dir_y 0] \
				    + [lindex $laby_data(direction_2d.$i) 1] * [lindex $dir_y 1]]
			
			# DOC On enregistre les segments de la grid en fonction des
			# paramètres x, y et index de direction (de 1 à 4).
			
			set laby_display($laby.$face.segment.$x.$y.$i) \
			    [$laby_display(canvas) create line $ox $oy $dx $dy -fill skyblue]
		    }
		}

		# Draw the point.
		
		set laby_display($laby.$face.point.$x.$y) \
		    [$laby_display(canvas) create oval \
			 [expr $ox - $rayon] [expr $oy - $rayon] \
			 [expr $ox + $rayon] [expr $oy + $rayon] \
			 -fill yellow -tag point]		
	    }
	}
    }

    # Set point over the lines.
    
    $laby_display(canvas) raise point
}

# Activate the cursor.
#
# param action on/off

proc cursor_display {laby action} {
    
    global laby_data
    global laby_display

    foreach face {front side top} {
	
	# Get the coords.

	set x [lindex $laby_data($laby.face.$face.cursor.position) 0]
	set y [lindex $laby_data($laby.face.$face.cursor.position) 1]

	# Update the oval depending on requested action.

	if {$action == "on"} {

	    $laby_display(canvas) itemconfigure \
		$laby_display($laby.$face.point.$x.$y) -fill red

	} else {

	    if {$action != "off"} {
		puts "Internal error: bad parameter"
	    }

	    $laby_display(canvas) itemconfigure \
		$laby_display($laby.$face.point.$x.$y) -fill yellow 
	}
    }
}

# Get the sextuple at the direction relative to the current cusor position.

proc get_point_from_direction_3d {laby direction} {

    global laby_data

    for {set i 0} {$i < 3} {incr i} {

	lappend cursor [expr \
			    [lindex $laby_data($laby.cursor.position) $i] \
			    + [lindex $direction [expr 2 * $i]] \
			    - [lindex $direction [expr 2 * $i + 1]]]
    }

    return [lindex $laby_data($laby.grid) [get_index_from_coord_3d $laby $cursor]]
}

# Get the quartet at the direction relative to the current cusor position.

proc get_point_from_direction_2d {laby face direction} {

    global laby_data

    for {set i 0} {$i < 2} {incr i} {

	lappend cursor [expr \
			    [lindex $laby_data($laby.face.$face.cursor.position) $i] \
			    + [lindex $direction [expr 2 * $i]] \
			    - [lindex $direction [expr 2 * $i + 1]]]
    }

    return [lindex $laby_data($laby.face.$face.grid) [get_index_from_coord_2d $laby $cursor]]
}

# Check if point on given direction index is free.
#
# Return 1 if the direction is ok, or 0 if the direction is ko.

proc direction_3d_ok {laby index} {

    global laby_data

    set direction {0 0 0 0 0 0}
    set status 0
            
    if {[lindex [get_point_from_cursor_3d $laby] $index] == 1} {
	
	set status 1

	# The way is on the grid and free (0 means no way, 2 means the way is
	# done).
	
	lset direction $index 1
	
	# DOC Calcul des coordonnées 3D du point à tester, puis recherche du
	# sextuplé dans le grid pour vérifier la présence d'un 2 dans la liste
	# (ie. le point est déjà utilisé par un chemin).

	set point [get_point_from_direction_3d $laby $direction]

	if {[lsearch $point 2] != -1} {
	    
	    # This point is used.
	    
	    set status 0
	}
    }

    return $status
}

# Check if the way is free.
# 
# If the direction is 0 on every direction then the test is false.

proc is_free_2d {laby face direction} {
    
    global laby_data

    set status 0
    
    set index [get_index_from_cursor_2d $laby $face]
    set point [lindex $laby_data($laby.face.$face.grid) $index]
    
    if {[lindex $point [lsearch $direction 1]] == 1} {
	
	set status 1
    }

    return $status
}

# Check if the point is used.

proc is_used_2d {laby face direction} {

    global laby_data
    
    set status 1

    set point [get_point_from_direction_2d $laby $face $direction]

    if {[lsearch $point 2] == -1} {	    

	# This point is not used.
	
	set status 0
    }

    return $status
}

# Search randomly for a direction available from the current cursor position.

proc random_free_3d_direction {laby direction} {
    
    global laby_data
    upvar $direction random_direction

    set status 1
    set direction_list [list]

    # Get the point in 3D grid.

    # DOC Pour un point donné du labyrinthe en cours de construction, si un
    # point adjacent est libre alors le chemin est libre. Par contre si le
    # chemin est libre, alors le point adjacent correspondant peut être libre ou
    # occupé. Pour faire avancer la construction du labyrinthe, on recherche les
    # points adjacents libres.

    # Check the 6 directions.

    for {set i 0} {$i < 6} {incr i} {

	# Add available direction to the list.
	
	if {[direction_3d_ok $laby $i] == 1} {

	    set sextuple {0 0 0 0 0 0}
	    lappend direction_list [lset sextuple $i 1]
	}
    }

    if {[llength $direction_list] > 0} {
	
	# DOC transformation d'un vecteur 3D dans ses projections sur les faces
	# en 2D: x => front x, top x, y => front y, side y, z => side x, top y.
		
	set good_direction [list]

	foreach dir $direction_list {
	    
	    # List the corresponding 2D directions.

	    set direction_2d(front) \
		[list \
		     [lindex $dir 0] [lindex $dir 1] \
		     [lindex $dir 2] [lindex $dir 3]]
	    
	    set direction_2d(side) \
		[list \
		     [lindex $dir 4] [lindex $dir 5] \
		     [lindex $dir 2] [lindex $dir 3]]
	    
	    set direction_2d(top) \
		[list \
		     [lindex $dir 0] [lindex $dir 1] \
		     [lindex $dir 4] [lindex $dir 5]]

	    # Validate the direction against 2D grids.
	    
	    # DOC On sait déjà, suite au test en 3D, que les chemins
	    # sont "sur la grille" (ie. pas besoin de tester le
	    # dépassement des bordures sur la projection en 2D) et
	    # "non tracé". On vérifie que sur la grille 2D le chemin
	    # et le point d'arrivée sont libres, ou le chemin est
	    # tracé. Dans le cas d'un déplacement nul sur la face, le
	    # test doit être passant, donc un des 2 tests doit être
	    # vrai. Dans le cas d'un déplacement nul, le premier test
	    # sera faux et le deuxième vrai.
	    
	    set check 1

	    foreach face $laby_data(face) {
		
		set free [is_free_2d $laby $face $direction_2d($face)]
		set used [is_used_2d $laby $face $direction_2d($face)]

		if {!(($free && !$used) || !$free)} {
		    
		    set check 0
		    break
		}
	    }
	    
	    if {$check == 1} {
		
		lappend good_direction $dir
	    }
	}


	if {[llength  $good_direction] > 0} {

	    # Get random direction.
	    
	    set rand_choice [lindex $good_direction [expr int(rand() * [llength $good_direction])]]
	    
	    for {set i 0} {$i < 3} {incr i} {
		
		lappend random_direction [expr \
					      [lindex $rand_choice [expr 2 * $i]] \
					      - [lindex $rand_choice [expr 2 * $i + 1]]]
	    }

	} else {

	    # No free direction available against 2D faces.
	
	    set status 0	    
	}
	
    } else {
	
	# No free direction available.
	
	set status 0
    }
    
    return $status
}

# Generate a labyrinthe and save it.

proc generate {size} {

    global laby_data    


	# Check for the goal.
	
	set goal 0
	
	# Create a new labyrinthe.
	
	set laby1 [laby_create $size]
	
	# Display the canvas.
	
	display $laby1 hexa
	
	# Let's go !
	
	while {1} {
	    
	    set direction [list]
	    
	    if {[random_free_3d_direction $laby1 direction] == 1} {
		
		# Move the cursor.
		
		move_3d $laby1 $direction
		
	    } else {
		
		# Go back one step.
		
		if {[move_back_3d $laby1] == 0} {
		    
		    # Cannot terminate the labyrinthe.
		    
		    break
		}
	    }
	    
	    # Check if match the goal (if not already matched).
	    
	    if {$goal == 0} {
		
		if {[lindex $laby_data($laby1.cursor.position) 0] == ($laby_data($laby1.size) - 1) \
			&& [lindex $laby_data($laby1.cursor.position) 1] == ($laby_data($laby1.size) - 1) \
			&& [lindex $laby_data($laby1.cursor.position) 2] == ($laby_data($laby1.size) - 1)} {
		    
		    set goal [expr [llength $laby_data($laby1.histo)] - 1]
		} 
	    }
	    
	    cursor_display $laby1 on
	    update
	    cursor_display $laby1 off
	}
	
	# Display some statistics.
	
	# number of step to the goal

	puts -nonewline "[format %03d $goal] "

	# number of 3D point used

	puts -nonewline "[format %03d $laby_data($laby1.used)] "

	# number of 2D points used on each face

	puts -nonewline "$laby_data($laby1.face.front.used) "
	puts -nonewline "$laby_data($laby1.face.side.used) "
	puts "$laby_data($laby1.face.top.used)"
	
	# If all the point are linked by the labyrinthe then make a file
	# for the game.
	
	set nb_point [expr $size * $size]
	if {($laby_data($laby1.face.front.used) == $nb_point) \
		&& ($laby_data($laby1.face.side.used) == $nb_point) \
		&& ($laby_data($laby1.face.top.used) == $nb_point)} {
	    
	    # Save the labyrinthe in file.
	    
	    set file_name [format %02d_%03d $size $goal]
	    set out [open $file_name w]
	    puts $out [array get laby_data $laby1.*]
	    close $out
	} 
	
	laby_delete $laby1

}

# Main.

# init default value 

set size 5
set gen 0

# Parse command line arguments.

while {[llength $argv] > 0 } {

    set flag [lindex $argv 0]

    switch -- $flag {

	"-size" {
	    set size  [lindex $argv 1]
	    set argv [lrange $argv 2 end]
	    if {$size < 2} {
		puts "Minimum size is 2 !"
		exit
	    }
	}

	"-gen" {
	    set gen 1
	    set argv [lrange $argv 1 end]
	}

	default { break }
    }
}

# init the canvas

set laby_display(canvas) \
    [canvas .c -height $laby_display(nb_pixel) -width $laby_display(nb_pixel) -background white]

pack $laby_display(canvas)
update 

if { $gen == 1 } {

    while {1} {

	generate $size

    }

} else {
    
    play_init $laby_display(canvas)

    array set laby_data [read [open 05_48]]
    # puts [array get laby_data]
    display laby8 hexa
    update

    puts "play the game !"

    vwait forever
}

exit
