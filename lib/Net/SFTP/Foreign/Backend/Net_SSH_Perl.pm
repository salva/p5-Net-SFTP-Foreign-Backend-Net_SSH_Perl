package Net::SFTP::Foreign::Backend::Net_SSH_Perl;

our $VERSION = '0.01';

use strict;
use warnings;

use Carp;
our @CARP_NOT = qw(Net::SFTP::Foreign);

use Net::SFTP::Foreign::Helpers;
use Net::SFTP::Foreign::Constants qw(SSH2_FX_BAD_MESSAGE
				     SFTP_ERR_REMOTE_BAD_MESSAGE);

sub _new {
    my $class = shift;

    eval {
        require Net::SSH::Perl;
        require Net::SSH::Perl::Constants;
        1;
    } or croak "Module Net::SSH::Perl required by $class can not be loaded";

    my $self = {};
    bless $self, $class;
}

sub _defaults { ( default_queue_size => 32 ) }

sub _channel_open_confirmation_handler {
    my ($self, $channel) = @_;
    my $packet = $channel->request_start("subsystem", 1);
    $packet->put_str("sftp");
    $packet->send;
}

sub _channel_failure_handler {
    my ($self, $channel, $packet) = @_;
    $self->{error} = 1;
    $channel->{ssh}->break_client_loop;
}

sub _channel_success_handler {
    my ($self, $channel, $packet) = @_;
    $channel->{ssh}->break_client_loop;
}

sub _init_transport {
    my ($self, $sftp, $opts) = @_;
    my $ssh = delete $opts->{ssh_perl};
    if (defined $ssh) {

    }
    else {
        my $host = delete $opts->{host};
        my $user = delete $opts->{user};
        my $password = delete $opts->{password};
        eval {
            $ssh = Net::SSH::Perl->new($host);
            $ssh->login($user, $password, 'supress_shell');
        }
    }
    $self->{ssh} = $ssh;
    my $bin = \$sftp->{_bin};
    my $channel = $self->{channel} = $ssh->_session_channel;

    $channel->open;
    $channel->register_handler( 91, # SSH2_MSG_CHANNEL_OPEN_CONFIRMATION
                               sub { $self->_channel_open_confirmation_handler(@_) });
    $channel->register_handler( 99, # SSH2_MSG_CHANNEL_SUCCESS
                               sub { $self->_channel_success_handler(@_) });
    $channel->register_handler(100, # SSH2_MSG_CHANNEL_FAILURE
                               sub { $self->_channel_failure_handler(@_) });

    $channel->register_handler(_output_buffer => sub {
                                   my ($channel, $buffer) = @_;
                                   $$bin .= $buffer->bytes;
                                   $channel->{ssh}->break_client_loop;
                               });
    $ssh->client_loop;
}

sub _sysreadn {
    my ($self, $sftp, $n) = @_;
    my $bin = \$sftp->{_bin};
    while (length $$bin < $n) {
        $self->{ssh}->client_loop;
        # FIXME: handle errors;
    }
    $n;
}

sub _do_io {
    my ($self, $sftp, $timeout) = @_;
    my $channel = $self->{channel};

    my $bin = \$sftp->{_bin};
    my $bout = \$sftp->{_bout};

    while (length $bout) {
        my $buf = substr($$bout, 0, 20480, '');
        my $channel->send_data($$bout);
    }

    defined $timeout and $timeout <= 0 and return;

    $self->_sysreadn($sftp, 4) or return undef;
    my $len = 4 + unpack N => $$bin;
    if ($len > 256 * 1024) {
	$sftp->_set_status(SSH2_FX_BAD_MESSAGE);
	$sftp->_set_error(SFTP_ERR_REMOTE_BAD_MESSAGE,
			  "bad remote message received");
	return undef;
    }
    $self->_sysreadn($sftp, $len);
}

sub after_init {}

1;
__END__

=head1 NAME

Net::SFTP::Foreign::Backend::Net_SSH_Perl - Net::SSSH::Perl backend for Net::SFTP::Foreign

=head1 SYNOPSIS

  $sftp = Net::SFTP::Foreign->new($host, backend => 'Net_SSH_Perl');

=head1 DESCRIPTION

Stub documentation for Net::SFTP::Foreign::Backend::Net_SSH_Perl, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Salvador Fandino, E<lt>salva@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Salvador Fandino

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
