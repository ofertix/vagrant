Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

#class repos {
#    file { '/etc/pki/rpm-gpg/laigu.pubkey':
#        owner  => root,
#        group  => root,
#        ensure => file,
#        mode   => 644,
#        source => '/vagrant/files/yum/laigu.pubkey',
#    }
#
#    file { '/etc/yum.repos.d/sl6propi-php.repo':
#        owner  => root,
#        group  => root,
#        ensure => file,
#        mode   => 644,
#        source => '/vagrant/files/yum/sl6propi-php.repo',
#        require => File["/etc/pki/rpm-gpg/laigu.pubkey"],
#    }
#}

class ssh-keys{
    file { '/home/vagrant/.ssh/id_rsa.pub':
        owner  => vagrant,
        group  => vagrant,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/ssh-keys/id_rsa.pub'
    }

    file { '/home/vagrant/.ssh/id_rsa':
        owner  => vagrant,
        group  => vagrant,
        ensure => file,
        mode   => 600,
        source => '/vagrant/files/ssh-keys/id_rsa'
    }
}

class dev-packages {

    $devPackages = [ "vim-enhanced", "curl", "git", "java-1.7.0-openjdk", "make", "diffutils", "man", "policycoreutils","htmldoc" ]
    package { $devPackages:
        ensure => "installed",
    }
}

class nginx-setup {
    
    include nginx

    file { ["/etc/nginx/vhost-available", "/etc/nginx/vhost-enabled"]:
        ensure => directory,
        require => Package["nginx"],
    }

    file { '/etc/nginx/conf.d/upstream-servers.conf':
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/nginx/conf.d/upstream-servers.conf',
        require => Package["nginx"],
    }
    file { '/etc/nginx/conf.d/include-vhosts.conf':
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/nginx/conf.d/include-vhosts.conf',
        require => Package["nginx"],
    }

    file { '/etc/nginx/vhost-available/ofertix.vhost':
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/nginx/vhosts/ofertix.vhost',
        require => File["/etc/nginx/vhost-available"],
    }

    file { "/etc/nginx/vhost-enabled/ofertix.vhost":
        notify => Service["nginx"],
        ensure => link,
        target => "/etc/nginx/vhost-available/ofertix.vhost",
        require => File["/etc/nginx/vhost-enabled"],
    }

    file { '/etc/nginx/vhost-available/ocio.vhost':
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/nginx/vhosts/ocio.vhost',
        require => File["/etc/nginx/vhost-available"],
    }

    file { "/etc/nginx/vhost-enabled/ocio.vhost":
        notify => Service["nginx"],
        ensure => link,
        target => "/etc/nginx/vhost-available/ocio.vhost",
        require => File["/etc/nginx/vhost-enabled"],
    }

    file { '/etc/nginx/vhost-available/nc.vhost':
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/nginx/vhosts/nc.vhost',
        require => File["/etc/nginx/vhost-available"],
    }

    file { "/etc/nginx/vhost-enabled/nc.vhost":
        notify => Service["nginx"],
        ensure => link,
        target => "/etc/nginx/vhost-available/nc.vhost",
        require => File["/etc/nginx/vhost-enabled"],
    }
}

class { "mysql":
    root_password => 'auto',
}

mysql::grant { 'ofertix2':
    mysql_privileges => 'ALL',
    mysql_password => 'ijwe90jejkw92',
    mysql_db => 'ofertix2',
    mysql_user => 'ofertix2',
    mysql_host => 'localhost',
}

class php-setup {

    $php = ["php-fpm", "php-cli", "php-devel", "php-gd", "php-mcrypt", "php-pecl-xdebug", "php-mysql", "php-pecl-memcache", "php-pecl-memcached",  "php-intl", "php-tidy", "php-imap", "php-pecl-imagick", "php-pecl-apc", "php-pecl-redis", "php-domxml-php4-php5", "php-soap"]

#    package { "mongodb":
#        ensure => present,
#        require => Package[$php],
#    }
#    package { "mongodb-server":
#        ensure => present,
#        require => Package[$php],
#    }

    package { $php:
        notify => Service['php-fpm'],
        ensure => latest,
        #require => File["/etc/yum.repos.d/sl6propi-php.repo"],
    }

    package { "apache2.2-bin":
        notify => Service['nginx'],
        ensure => purged,
        require => Package[$php],
    }

    package { "ImageMagick":
        ensure => present,
        require => Package[$php],
    }

    package { "phpmyadmin":
        ensure => present,
        require => Package[$php],
    }

#    exec { 'pecl install mongo':
#        notify => Service["php-fpm"],
#        command => '/usr/bin/pecl install --force mongo',
#        logoutput => "on_failure",
#        require => Package[$php],
#        before => [File['/etc/php.ini'], File['/etc/php-fpm.conf'], File['/etc/php-fpm.d/www.conf']],
#        unless => "/usr/bin/php -m | grep mongo",
#    }

    file { '/etc/php.ini':
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/php/php.ini',
        require => Package[$php],
    }

    file { '/etc/php-fpm.conf':
        notify => Service["php-fpm"],
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/php/php-fpm.conf',
        require => Package[$php],
    }

    file { '/etc/php-fpm.d/www.conf':
        notify => Service["php-fpm"],
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/php/php-fpm.d/www.conf',
        require => Package[$php],
    }

    file { '/etc/php.d/xdebug.ini':
        notify => Service["php-fpm"],
        owner  => root,
        group  => root,
        ensure => file,
        mode   => 644,
        source => '/vagrant/files/php/php.d/xdebug.ini',
        require => Package[$php],
    }

    service { "php-fpm":
        ensure => running,
	enable => true,
        require => Package["php-fpm"],
    }

#    service { "mongod":
#        ensure => running,
#        require => Package["mongodb-server"],
#    }
}

class redis {
    package { "redis":
        ensure => latest,
    }
    service { "redis":
        ensure => running,
        enable => true,
        require => Package["redis"],
    }
}

class prepare-project {
    file { "/var/log/ofertix2":
        ensure => directory,
        owner => nobody,
        group => nobody,
        mode => 666,
    }

    host { 'la1':
        ip => '91.223.61.93',
        host_aliases => [ 'la1p' ]
    }

    host { 'ofertix2':
 	ip => '127.0.0.1',
        host_aliases => ['www.ofertixlocal.com','ocio.ofertixlocal.com','ofertix2frontend','ofertix2mobile','www.nclocal.com']
    }

    #$enableservice = ["redis"]
    #service { $enableservice:
    #    ensure => running,
    #    enable => true,
    #    require => Package["$enableservice"],
    #}

}

#class composer {
#    exec { 'install composer php dependency management':
#        command => 'curl -s http://getcomposer.org/installer | php -- --install-dir=/usr/bin && mv /usr/bin/composer.phar /usr/bin/#composer',
#        creates => '/usr/bin/composer',
#        require => [Package['php-cli'], Package['curl']],
#    }
#}

#class memcached {
#    package { "memcached":
#        ensure => present,
#    }
#}

resources { "firewall":
    purge => true,
    require => Package["policycoreutils"],
}


#firewall { '000 accept all icmp':
#    proto   => 'icmp',
#    action  => 'accept',
#}


include ssh-keys
#include repos
include dev-packages
include nginx-setup
include php-setup
include phpqatools
include redis
include prepare-project
