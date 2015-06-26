freeswitch_home='/usr/local/freeswitch/'


#copy *.conf.xml
for dir in `find ./ -name *.xml`
do
  echo 'cp -fr' $dir $freeswitch_home$dir
  cp -fr $dir $freeswitch_home$dir
done

#copy scripts
echo 'rm -fr' $freeswitch_home'scripts'
rm -fr $freeswitch_home'scripts'


echo 'cp -fr ./scripts' $freeswitch_home'scripts'
cp -fr ./scripts $freeswitch_home'scripts'

echo '<<<<<< done!'