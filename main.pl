#!/usr/bin/perl

use strict;
use warnings;

use Gtk2 '-init';
use Gtk2::GladeXML;
use Glib qw/TRUE FALSE/;

use IO::Socket::INET;

use Options;

#---------------------------------------------------------------------
#  Options
#---------------------------------------------------------------------
my $socket;

my $options = Options->new(
	port => '1508',
	server => '127.0.0.1',
	nickname => 'Fulano',
	connected => 0,
	is_server => 1
);

#---------------------------------------------------------------------
#  GTK+ Widgets
#---------------------------------------------------------------------
my $glade = Gtk2::GladeXML->new("ugmchat.glade");
my $tooltip = Gtk2::Tooltips->new;

# *** WINDOWS ***
my $window = $glade->get_widget("window1");
my $dialog = $glade->get_widget("window2");

# *** MENU ITEMS ***
my $exit_menu_item = $glade->get_widget("imagemenuitem5");
my $about_menu_item = $glade->get_widget('imagemenuitem10');

# *** DIALOG CONNECTION ***
my $nickname_entry_box = $glade->get_widget('entry1');
my $server_entry_box = $glade->get_widget('entry2');
my $port_entry_box = $glade->get_widget('entry3');

my $start_server_radio_button = $glade->get_widget('radiobutton1');
my $use_server_radio_button = $glade->get_widget('radiobutton2');

my $clear_nickname_button = $glade->get_widget('button7');
my $clear_server_and_port_button = $glade->get_widget('button6');

my $cancel_dialog_button = $glade->get_widget('button5');
my $connect_dialog_button = $glade->get_widget('button4');

# *** CHAT PANELS ***
my $input_entry_box = $glade->get_widget('textview1');
my $output_entry_box = $glade->get_widget('textview2');

# *** TOOLBAR ***
my $toolbar = $glade->get_widget('toolbar1');
my $disconnect_toolbar_item = Gtk2::ToolButton->new_from_stock('gtk-disconnect');
my $connect_toolbar_item = Gtk2::ToolButton->new_from_stock('gtk-connect');
my $exit_toolbar_item = Gtk2::ToolButton->new_from_stock('gtk-quit');

#---------------------------------------------------------------------
#  Widgets initialisation
#---------------------------------------------------------------------
$window->set_title("UGM Chat 1.0");
$window->signal_connect(destroy => sub {Gtk2->main_quit});

#---------------------------------------------------------------------
#  Menu items
#---------------------------------------------------------------------
$exit_menu_item->signal_connect(activate => sub {Gtk2->main_quit});
$about_menu_item->signal_connect(activate => sub {Gtk2->main_quit});

#---------------------------------------------------------------------
#  Configuration dialog toolbox
#---------------------------------------------------------------------
$start_server_radio_button->signal_connect(
	toggled => sub {
		if ($start_server_radio_button->get_active) {
			$server_entry_box->set_sensitive(FALSE);
			$port_entry_box->set_sensitive(FALSE);
			$options->is_server(TRUE);
		}
	}
);

$use_server_radio_button->signal_connect(
	toggled => sub {
		if ($use_server_radio_button->get_active) {
			$server_entry_box->set_sensitive(TRUE);
			$port_entry_box->set_sensitive(TRUE);
			$options->is_server(FALSE);
		}
	}
);

$clear_nickname_button->signal_connect(
	clicked => sub {
		$nickname_entry_box->set_text("");
		$nickname_entry_box->grab_focus;
		$server_entry_box->grab_focus
	}
);

$clear_server_and_port_button->signal_connect(
	clicked => sub {
		$server_entry_box->set_text("");
		$port_entry_box->set_text("");
		$server_entry_box->grab_focus
	}
);

$cancel_dialog_button->signal_connect(clicked => sub {$dialog->hide});

$connect_dialog_button->signal_connect(
	clicked => sub {
		# *** SERVER ***
		#$socket = new IO::Socket::INET (
		#    LocalHost => '127.0.0.1',
		#    LocalPort => '0155',
		#    Proto => 'tcp',
		#    Listen => 1,
		#    Reuse => 1
		#) or die "Oops: $! \n";
		#print "Waiting for the Client.\n";


		# *** CLIENT ***
		#$socket = new IO::Socket::INET (
		#  PeerHost => '127.0.0.1',
		#  PeerPort => '0155',
		#  Proto => 'tcp',
		#) or die "$!\n";

		#print "Connected to the Server.\n";

		$options->server($server_entry_box->get_text);
		$options->port($port_entry_box->get_text);

		$socket = IO::Socket::INET->new(
			LocalHost => $options->server,
			LocalPort => $options->port,
			Proto => 'tcp',
			Listen => $options->is_server,
			Reuse => 1
		) or die "Cannot create the socket";

		$dialog->hide;
		$connect_toolbar_item->set_sensitive(FALSE);
		$disconnect_toolbar_item->set_sensitive(TRUE);

		$input_entry_box->set_sensitive(TRUE);
		$input_entry_box->grab_focus;

		$output_entry_box->set_sensitive(TRUE);
		my $buffer = $output_entry_box->get_buffer;

		my $text;

		if ($options->is_server) {
			$text = "* Servidor iniciado a las ". localtime;
		} else {
			$text = "* Conectandose al servidor: ".$options->server." a las ".localtime;
		}

		$buffer->set_text($text);
		$output_entry_box->set_buffer($buffer);
	}
);

$disconnect_toolbar_item->signal_connect(
	'clicked' => sub {
		$socket->close;
		$connect_toolbar_item->set_sensitive(TRUE);
		$disconnect_toolbar_item->set_sensitive(FALSE);

		#$input_entry_box->set_text("");
		$input_entry_box->set_sensitive(FALSE);
		$input_entry_box->set_sensitive(FALSE);

		my $buffer = $output_entry_box->get_buffer;
		my $text = $buffer->get_text($buffer->get_start_iter, $buffer->get_end_iter, 1);
		$text .= "\n* Desconectado a las ".localtime;
		$buffer->set_text($text);
		$output_entry_box->set_buffer($buffer);
		$output_entry_box->set_sensitive(FALSE);
	}
);

#---------------------------------------------------------------------
#  Toolbar
#---------------------------------------------------------------------
$toolbar->set_icon_size('large-toolbar');
$toolbar->set_show_arrow(FALSE);

$exit_toolbar_item->set_tooltip($tooltip, "Salir del programa", "");
$exit_toolbar_item->signal_connect('clicked' => sub {Gtk2->main_quit});
$toolbar->insert($exit_toolbar_item, -1);

$connect_toolbar_item->set_tooltip($tooltip, "Conectarse a un servidor", "");

$connect_toolbar_item->signal_connect(
	'clicked' => sub {
		$nickname_entry_box->set_text($options->nickname);
		$server_entry_box->set_text($options->server);
		$port_entry_box->set_text($options->port);
		$dialog->show;
	}
);

$toolbar->insert($connect_toolbar_item, -1);

$disconnect_toolbar_item->set_tooltip($tooltip, "Desconectarse del servidor", "");
$disconnect_toolbar_item->set_sensitive(FALSE);

$toolbar->insert($disconnect_toolbar_item, -1);

$toolbar->insert(Gtk2::SeparatorToolItem->new, 1);

#---------------------------------------------------------------------
#  Main window
#---------------------------------------------------------------------
$input_entry_box->set_sensitive(FALSE);
$output_entry_box->set_sensitive(FALSE);

$window->show_all;
Gtk2->main;
