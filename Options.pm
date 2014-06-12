package Options;

use Moose;

has 'server' => (is => 'rw');
has 'port' => (is => 'rw', isa => 'Num');
has 'nickname' => (is => 'rw', isa => 'Str');
has 'connected' => (is => 'rw', isa => 'Bool');
has 'is_server' => (is => 'rw', isa => 'Bool');

1;
