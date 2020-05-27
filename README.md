<h1>California Renewables: predicting solar generation</h1>

<h3>California is leading America and the world on clean energy</h3>



<p>Over the past 10 years, California has established itself as a prominent leader in adopting and implementing ambitious clean energy policies. California matters – economically and environmentally – not only in the American but in the global context. If California were a country, it would be the world’s 5th largest economy, bigger than the UK, France, or India.</p>
<p>The recent&nbsp;<a href="https://www.energy.ca.gov/programs-and-topics/programs/renewables-portfolio-standard">Renewables Portfolio Standard</a>&nbsp;implemented in 2018 requires that 50% of California's electricity come from&nbsp;zero-carbon sources&nbsp;by 2025, 60% by 2025, and 100% by 2045. The cumulative result of these bold policies and unprecedented private investment is encouraging. Over the last decade, California was able to steadily reduce the physical volumes of fossil fuel-derived generation by about 25% while growing the economy by 40%.</p>



<div class="wp-block-image"><figure class="alignleft size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-341611-W0cmiQkQ-300x211.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-341611-W0cmiQkQ-600x423.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-341611-W0cmiQkQ-768x541.png 768w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-341611-W0cmiQkQ.png 809w' width='600' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-341611-W0cmiQkQ.png" alt="" class="wp-image-63239" /></figure></div>




<p>California's transition towards renewable energy comes with significant challenges on the economic, technological, and regulatory fronts. My&nbsp;<a href="https://levonian.shinyapps.io/california_renewables/">Shiny app</a>&nbsp;investigates some of these challenges and explores a machine learning approach to address one of the biggest uncertainties: the variability of solar generation.</p>
<p>The project has two specific objectives:</p>
<ol>
<li>To identify the most accurate forecasting method and to assess possible economic benefits,</li>
<li>To provide a primer on using various techniques for autoregressive time series forecasting.</li>
</ol>



<h3>Current challenges: too much solar?</h3>



<p>About 80% of California’s energy is delivered by the California Independent System Operator (<a href="http://caiso.com">CAISO</a>), a non-profit organization responsible for balancing electricity supply and demand and ensuring California’s grid reliability.&nbsp; The source data for the Shiny app came from the 10 years of hourly electric generation published by CAISO (<a href="http://content.caiso.com/green/renewrpt/20200430_DailyRenewablesWatch.txt">a sample of the daily data</a>). &nbsp;</p>
<p>While the annual trend looks like a steady buildup of the renewable generation, monthly breakdown shows significant seasonal variation. Solar generation spikes at summer to about 3 TWh/month with close to 14 hours of daylight (and higher intensity) and goes down to about 1 TWh/month in December. Fortunately, seasonal solar production is peaking in sync with surging summer demand driven by air conditioning:</p>



<div class="wp-block-image"><figure class="alignleft size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-560651-4cFqDNXh-300x210.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-560651-4cFqDNXh-600x420.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-560651-4cFqDNXh-768x538.png 768w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-560651-4cFqDNXh.png 804w' width='600' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-560651-4cFqDNXh.png" alt="" class="wp-image-63240" /></figure></div>



<p>Yet despite this resounding success at the big picture level, policymakers, media, and CAISO itself describe the situation as alarming. You can stumble upon recounts of how California <em>grapples</em>&nbsp;with ever-growing amounts of renewable energy, and what to do with the solar energy that CAISO has to <em>curtail</em>.</p>



<h3>The Duck Curve</h3>



<p>The problem becomes apparent when we zoom in to the hourly level. Solar generation in California peaks at 2-4 pm, while traditional power plants are turned down to the minimum. From around 4 pm to 8 pm, solar generation declines to zero – exactly at the time when demand is peaking, which requires large and fast power ramping from traditional sources.</p>
<p>This is what April 30, 2020 looked like at CAISO:</p>



<div class="wp-block-image"><figure class="alignleft size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-881462-nfQ81Ofj-300x218.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-881462-nfQ81Ofj-600x436.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-881462-nfQ81Ofj-768x559.png 768w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-881462-nfQ81Ofj.png 796w' width='600' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-881462-nfQ81Ofj.png" alt="" class="wp-image-63242" /></figure></div>



<p>Note also that the short-term power storage capacity (so far confined largely to lithium ion technology) is too small to smooth out this daily solar cycle in a meaningful way. In other words, today, energy needs to be consumed the instant it is generated.</p>
<p>CAISO coined the term ‘the duck curve’ to describe the formidable intraday swings in the net load (total demand less solar and wind generation).&nbsp;</p>
<p>This is how the net load on the same day (April 30) has changed from 2010 to 2020:</p>



<figure class="wp-block-image size-large is-resized"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-161969-JjKVARiv-300x213.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-161969-JjKVARiv-600x426.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-161969-JjKVARiv-768x545.png 768w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-161969-JjKVARiv.png 796w' sizes='(max-width: 796px) 100vw, 796px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-161969-JjKVARiv.png" alt="" class="wp-image-63243" width="522" height="370" /></figure>



<p>Over the past decade, the duck’s belly has got deeper and deeper, and today these swings amount to 15GW capacity and more in a matter of 3-4 hours. To put this into perspective, this is roughly equivalent to the total installed capacity of a medium-sized country such as Switzerland or Israel. In other words, CAISO has to turn an entire country’s electric generation on and back off, every day, to smooth out the solar output. This is the greatest challenge facing renewable energy in California today.</p>



<h3>Forecasting Solar Generation</h3>



<p>And yet there is another aspect of solar that makes it even more complicated for CAISO: the poor predictability. Not only is solar generation intermittent, it is also inherently irregular, affected by the cloud cover and numerous other factors such as dust, precipitation, and temperature. Within a typical month, the actual daily solar generation may fluctuate by 30-50%:</p>



<div class="wp-block-image"><figure class="alignleft size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-323935-zHMX7fLp-300x212.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-323935-zHMX7fLp-600x425.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-323935-zHMX7fLp-768x544.png 768w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-323935-zHMX7fLp.png 805w' width='600' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-323935-zHMX7fLp.png" alt="" class="wp-image-63580" /></figure></div>



<p>CAISO needs to forecast this volatile supply to balance the entire system and ensure grid stability. That’s why predicting solar and wind generation is at the center of CAISO’s attention. CAISO runs many different types of forecasts ranging from 15 minutes ahead to 1 hour ahead to 24 hours and beyond.</p>
<p>The goal of this project is to identify the best method of predicting the solar generation for the purely autoregressive model in the absence of any external inputs. Of the 5 forecasting methods analyzed, the best accuracy was achieved by an ensemble of a classical autoregressive SARIMA and a recurrent neural network.</p>
<p>On average, this ensemble improved forecasting accuracy by about 0.07-0.25 GW compared to the best non-machine learning method (Differencing):</p>



<figure class="wp-block-image size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-263989-z1JXskqK-300x125.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-263989-z1JXskqK.png 476w' sizes='(max-width: 476px) 100vw, 476px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-263989-z1JXskqK.png" alt="" class="wp-image-63581" /></figure>



<p>For CAISO, this improved accuracy would translate into less reserve capacity requirements. California’s current Capacity Procurement Mechanism sets the price for extra capacity at $75 kW-years, which would translate into at least $5 million annual saving for CAISO.</p>



<h3>Conclusions</h3>



<p>Solar generation is the centerpiece of California’s bold clean energy policies. However, it is intermittent and irregular. My <a href="https://levonian.shinyapps.io/california_renewables/">Shiny app</a> shows that uncertainty in solar generation forecasts can be reduced significantly by machine learning methods, which would lead to sizable economic benefits for CAISO.</p>
<p>&nbsp;</p>



<h2><strong>Autoregressive time series forecasting: A technical primer</strong></h2>



<p>The dataset for this project consists of 87,936 timesteps: slightly over 10 years of hourly electricity generation data for the period of April 20, 2010–April 30, 2020 provided by CAISO.</p>
<p>Each forecasting model was trained on data ending on December 31, 2018.&nbsp; Incremental retraining was not implemented – both autoregressive SARIMA and RNNs took from 10 to 20 minutes to train on Tesla P100 GPU, so retraining for each new timestep was not feasible.</p><div class='mailmunch-forms-in-post-middle' style='display: none !important;'></div>
<p>All forecasts are built on actual hourly series for the 1-hour ahead horizon. Models’ performance is tested and compared on 2019-2020 test data, i.e. completely out-of-sample.</p>



<h3>Naïve Forecast</h3>



<p>In time series forecasting, the naive prediction of F(t+1)=F(t) often serves as a basic benchmark because it turns out surprisingly hard to beat (especially in aperiodic, low signal-to-noise environments). CAISO uses such benchmarks (also called&nbsp;<em>persistence forecasts</em>) extensively in tactical planning.</p>
<p><span style="font-size: inherit">Below is a naïve forecast of the solar generation for the last 3 days of April 2020, a typical picture of how volatile the generation is. The MAE of the naïve forecast over these three days is 0.87 GW. </span></p>



<figure class="wp-block-image size-large is-resized"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-173126-TIMBYtqn-300x211.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-173126-TIMBYtqn-600x423.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-173126-TIMBYtqn-768x541.png 768w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-173126-TIMBYtqn.png 793w' sizes='(max-width: 793px) 100vw, 793px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-173126-TIMBYtqn.png" alt="" class="wp-image-63245" width="516" height="363" /></figure>



<h3>Differenced Forecast</h3>



<p>A slightly less naïve approach, applicable only for periodic series, relies on smoothing the signal as compared to previous periods:</p>



<figure class="wp-block-image size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-340321-tZud2mzp-300x17.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-340321-tZud2mzp-600x35.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-340321-tZud2mzp.png 638w' sizes='(max-width: 638px) 100vw, 638px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-340321-tZud2mzp.png" alt="" class="wp-image-63227" /></figure>



<p>This forecast does not learn any patterns directly from the data. This is essentially a potentially moving average MA(1) process for the once-differenced I(1) series with fixed coefficients. A grid search of relevant parameters produced the optimal configuration, which turned out to be very simple:</p>



<figure class="wp-block-image size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-992052-Z6rb7825-300x19.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-992052-Z6rb7825.png 467w' sizes='(max-width: 467px) 100vw, 467px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-992052-Z6rb7825.png" alt="" class="wp-image-63229" /></figure>



<p>This is essentially forecasting the next hour as the current generation (naïve) adjusted for the difference in generation between the same adjacent timesteps 24 hours ago. We can see from the graph that this 24-hour differencing forecast fits the data remarkably well, producing a simple and reliable benchmark.&nbsp;</p>
<p>The three-day MAE is 0.33 GW, which is less than 40% of the naïve error.</p>



<figure class="wp-block-image size-large is-resized"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-818959-O85rRvRz-300x211.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-818959-O85rRvRz-600x423.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-818959-O85rRvRz-768x541.png 768w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-818959-O85rRvRz.png 802w' sizes='(max-width: 802px) 100vw, 802px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-818959-O85rRvRz.png" alt="" class="wp-image-63247" width="522" height="367" /></figure>



<h3>SARIMA Forecast</h3>



<p>My third approach was to implement a classical SARIMA autoregressive model, which was motivated by the following:</p>
<ul>
<li>The strict 24-hour period warrants at least one order of differencing.</li>
<li>
<p>When there is inertia and mean-reversion in the underlying data-generating process, it is best described by a moving average MA(q) process. There is clearly inertia in cloud cover, precipitation, and temperature, which tend to affect solar generation in multi-hour stretches.  </p>
</li>
<li>The regular autoregressive part of the process is inferred from the shape of ACF/PACF correlograms and tested by a grid search.</li>
</ul>
<p>The raw hourly generation is of course highly autocorrelated: </p>



<figure class="wp-block-image size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-195716-Jo2B34lW-300x192.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-195716-Jo2B34lW.png 466w' sizes='(max-width: 466px) 100vw, 466px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-195716-Jo2B34lW.png" alt="" class="wp-image-63230" /></figure>



<p>The raw process is highly non-stationary, with trend and seasonality. We achieve quasi-stationarity only after double differencing by 24 and 1 periods. The ACF for this I(2) series shows strong autocorrelation for h=1 and h=24 time shifts:</p>



<figure class="wp-block-image size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-250931-MBgBrJLw-300x198.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-250931-MBgBrJLw.png 463w' sizes='(max-width: 463px) 100vw, 463px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-250931-MBgBrJLw.png" alt="" class="wp-image-63231" /></figure>



<p>We can conclude that the differenced series is probably a MA(1) process. This means that the model will adjust its predictions by some portion of the error it made in the previous time step, which may have been caused by a random shock such as cloud cover.</p>
<p>Grid search for the best configuration produces the following compact SARIMA:</p>



<figure class="wp-block-image size-large"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-468018-FzwBs3Wu-300x17.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-468018-FzwBs3Wu.png 590w' sizes='(max-width: 590px) 100vw, 590px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-468018-FzwBs3Wu.png" alt="" class="wp-image-63232" /></figure>



<p>SARIMA model works particularly well in this case because solar generation is inherently periodic and strongly autocorrelated. This is our best forecast with MAE = 0.25 GW&nbsp; (all metrics are out-of-sample):</p>



<figure class="wp-block-image size-large is-resized"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-630081-8mYgR6Kq-300x210.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-630081-8mYgR6Kq-600x419.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-630081-8mYgR6Kq-768x537.png 768w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-630081-8mYgR6Kq.png 813w' sizes='(max-width: 813px) 100vw, 813px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-630081-8mYgR6Kq.png" alt="" class="wp-image-63249" width="508" height="355" /></figure>



<h3>Recurrent Neural Network</h3>



<p>Finally, I deployed an RNN-based neural network that was trained on approximately 2.5 years of data, from June 2016 to December 2018, and tested on 2019-2020 data. Each training sample consisted of 48 hours of historical generation and the network was trained to predict the following hour’s generation.</p>
<p>RNN's error was worse than SARIMA's, at 0.33 GWh for our 3-day sample. Apparently, there is little non-linearity nor long-term dependencies, which RNNs are very good at.</p>
<p><span style="font-size: inherit">In particular, RNN seems to miss the peaks of the cycle more than SARIMA. If this bias proves to be systematic, it may be possible to compensate for.&nbsp; </span></p>



<figure class="wp-block-image size-large is-resized"><img srcset='https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-393274-KkGxfwwS-300x215.png 300w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-393274-KkGxfwwS-600x429.png 600w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-393274-KkGxfwwS-768x549.png 768w, https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-393274-KkGxfwwS.png 800w' sizes='(max-width: 800px) 100vw, 800px' src="https://nycdsa-blog-files.s3.us-east-2.amazonaws.com/2020/05/dmitri-levonian/image-393274-KkGxfwwS.png" alt="" class="wp-image-63251" width="500" height="357" /></figure>



<h3>Ensemble</h3>



<p>The best accuracy is obtained by averaging the SARIMA and RNN models. A simple 50/50 average achieves a sizable decrease in Mean Absolute Error compared to either SARIMA or RNN alone.</p>
<p>Note that all of the models above are autoregressive. Including exogenous predictors such as weather forecasts would further improve the accuracy. However, it would imply additional operational complexity for CAISO since the cloud cover, precipitation and temperature forecasts need to be accounted for each of the 700+ of California’s solar sites.</p>
<p><strong> </strong>To learn more about how to build a SARIMA model with statsmodels API, how to deploy a time-series data pipeline in TensorFlow, or how to set up a learning rate decay schedule, please visit the project’s <a href="https://github.com/dlevonian/california_renewables">github</a>.</p>
