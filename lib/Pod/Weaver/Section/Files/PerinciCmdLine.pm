package Pod::Weaver::Section::Files::PerinciCmdLine;

# DATE
# VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::DetectPerinciCmdLineScript';
with 'Pod::Weaver::Role::DumpPerinciCmdLineScript';
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use List::Util qw(first);
use Moose::Autobox;

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename} || 'file';
    if ($filename !~ m!^(bin|script)/!) {
        $self->log_debug(["skipped file %s (not bin/script)", $filename]);
        return;
    }

    my $res = $self->detect_perinci_cmdline_script($input);
    if ($res->[0] != 200) {
        die "Can't detect Perinci::CmdLine script for $filename: $res->[0] - $res->[1]";
    } elsif (!$res->[2]) {
        $self->log_debug(["skipped file %s (not a Perinci::CmdLine script: %s)", $filename, $res->[3]{'func.reason'}]);
        return;
    }

    $res = $self->dump_perinci_cmdline_script($input);
    if ($res->[0] != 200) {
        die "Can't dump Perinci::CmdLine script for $filename: $res->[0] - $res->[1]";
    }
    my $cli = $res->[2];

    # workaround because currently the dumped object does not contain all
    # attributes in the hash (Moo/Mo issue?), we need to access the attribute
    # accessor method first to get them recorded in the hash. this will be fixed
    # in the dump module in the future.
    {
        local $0 = $filename;

        local @INC = ("lib", @INC);
        eval "use " . ref($cli) . "()";
        die if $@;

        unless ($cli->read_config) {
            $self->log_debug(["skipped file %s (script does not read config)", $filename]);
            return;
        }

        my $text;
        my $config_filename = $cli->config_filename // $cli->program_name . ".conf";
        my $config_dirs = $cli->{config_dirs} // ['~', '/etc'];

        for my $config_dir (@{$config_dirs}) {
            $text .= "$config_dir/$config_filename\n\n";
        }

        $self->add_text_to_section($document, $text, 'FILES');
    }
}

no Moose;
1;
# ABSTRACT: Add a FILES section for Perinci::CmdLine-based scripts

=for Pod::Coverage weave_section

=head1 SYNOPSIS

In your C<weaver.ini>:

 [Files::PerinciCmdLine]


=head1 DESCRIPTION


=head1 SEE ALSO

L<Perinci::CmdLine>

=cut
