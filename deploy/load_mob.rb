depends_on_mob 'common_mob'

load_lib(mob_root+'lib')         if (mob_root+'lib').exist?
load_targets(mob_root+'targets') if (mob_root+'targets').exist?
load_acts(mob_root+'acts')       if (mob_root+'acts').exist?
