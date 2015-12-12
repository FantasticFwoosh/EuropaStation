//-------------------------------
// Airlock control panel
//  Handles user interaction with the airlock and passes commands to the wifi sender for execution
//-------------------------------
/obj/machinery/airlock
	name = "airlock control panel"
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "airlock_control_standby"
	anchored = 1
	density = 0
	use_power = 1
	idle_power_usage = 10
	waterproof = 1

	var/processing
	var/chamber_pressure

	//target pressures for cycling to interior and exterior - configurable in dream maker
	var/_interior_target = ONE_ATMOSPHERE
	var/_exterior_target = ONE_ATMOSPHERE*12	//Who lives in a pineapple under the sea? We do!

	var/_wifi_id
	var/datum/wifi/sender/airlock/wifi_sender
	var/datum/wifi/receiver/button/airlock/wifi_receiver

/obj/machinery/airlock/initialize()
	..()
	if(_wifi_id)
		wifi_sender = new(_wifi_id, src)
		wifi_receiver = new("[_wifi_id]_control", src)	//receiver sets it's own network id with a "control" suffix for receiving remote button commands
	update_icon()

/obj/machinery/airlock/update_icon()
	if(use_power)
		if(processing)
			icon_state = "airlock_control_process"
		else
			icon_state = "airlock_control_standby"
	else
		icon_state = "airlock_control_off"

/obj/machinery/airlock/Destroy()
	qdel(wifi_sender)
	qdel(wifi_receiver)
	wifi_sender = null
	wifi_receiver = null
	return ..()

/obj/machinery/airlock/attack_ai(mob/user)
	ui_interact(user)

/obj/machinery/airlock/attack_hand(mob/user)
	if(!user.IsAdvancedToolUser())
		return 0
	ui_interact(user)

/obj/machinery/airlock/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/data[0]

	wifi_sender.update_chamber_pressure()

	data = list(
		"chamber_pressure" = chamber_pressure,
		"processing" = processing,
	)

	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)

	if (!ui)
		ui = new(user, src, ui_key, "airlock_console.tmpl", name, 470, 290)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/airlock/Topic(href, href_list)
	if(..())
		return

	usr.set_machine(src)
	add_fingerprint(usr)

	switch(href_list["command"])
		if("cycle_ext")
			cycle_exterior()
		if("cycle_int")
			cycle_interior()
		if("abort")
			abort()

	return 1

/obj/machinery/airlock/proc/cycle_interior()
	if(wifi_sender && !processing)
		processing = 1
		update_icon()
		wifi_sender.cycle_interior(_interior_target)
		processing = 0
		update_icon()

/obj/machinery/airlock/proc/cycle_exterior()
	if(wifi_sender && !processing)
		processing = 1
		update_icon()
		wifi_sender.cycle_exterior(_exterior_target)
		processing = 0
		update_icon()

/obj/machinery/airlock/proc/abort()
	if(wifi_sender && processing)
		wifi_sender.abort()
		processing = 0
		update_icon()
