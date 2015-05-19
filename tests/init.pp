class { 'maw':
  sites              => {
    'www.mysite.com' => {},
    'www.myblog.com' => {db_manage => false, db_user_manage => false},
  },
}
