cd assets
curl -O -L https://raw.github.com/flot/flot/master/jquery.flot.js
curl -O -L https://raw.github.com/flot/flot/master/jquery.flot.time.js
curl -O -L https://raw.github.com/flot/flot/master/jquery.flot.navigate.js
curl -O -L https://raw.github.com/krzysu/flot.tooltip/master/js/jquery.flot.tooltip.js
curl -O https://raw.github.com/jashkenas/coffee-script/master/extras/coffee-script.js
curl -O https://raw.github.com/gradus/coffeecup/master/lib/coffeecup.js
curl -O http://code.jquery.com/jquery-1.9.1.min.js
curl -O -L https://raw.github.com/mde/timezone-js/master/src/date.js

curl ftp://ftp.iana.org/tz/tzdata-latest.tar.gz -o tz/tzdata-latest.tar.gz
tar -xvzf tz/tzdata-latest.tar.gz -C tz
rm tz/tzdata-latest.tar.gz
cd -
