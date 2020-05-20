use ExtUtils::MakeMaker;
use YAML;

my $config = YAML::LoadFile((glob('./plugins/*/config.yaml'))[0]);

WriteMakefile(
    NAME     => $config->{name},
    VERSION  => $config->{version},
    SKIP     => [qw(distdir)],
    DISTNAME => $config->{name},
);

sub MY::top_targets {
    << 'Makefile';
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir
	$(NOECHO) $(NOOP)

Makefile
}
