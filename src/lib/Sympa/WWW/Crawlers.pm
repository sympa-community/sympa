# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique

# NOTE: This file is auto-generated.  Don't edit it manually.
# Instead, modifications should be made on support/make_crawlers.pl file.

package Sympa::WWW::Crawlers;

use strict;
use warnings;

use constant crawler => qr{
  (
    Googlebot\/
  | Googlebot-Mobile
  | Googlebot-Image
  | Googlebot-News
  | Googlebot-Video
  | AdsBot-Google([^-]|$)
  | AdsBot-Google-Mobile
  | Feedfetcher-Google
  | Mediapartners-Google
  | Mediapartners[ ]\(Googlebot\)
  | APIs-Google
  | Google-InspectionTool
  | Storebot-Google
  | GoogleOther
  | bingbot
  | Slurp
  | [wW]get
  | LinkedInBot
  | Python-urllib
  | python-requests
  | aiohttp
  | httpx
  | libwww-perl
  | httpunit
  | Nutch
  | Go-http-client
  | phpcrawl
  | msnbot
  | jyxobot
  | FAST-WebCrawler
  | FAST[ ]Enterprise[ ]Crawler
  | BIGLOTRON
  | Teoma
  | convera
  | ^Seekbot
  | Gigabot
  | Gigablast
  | exabot
  | ia_archiver
  | GingerCrawler
  | webmon[ ]
  | HTTrack
  | grub\.org
  | UsineNouvelleCrawler
  | antibot
  | netresearchserver
  | speedy
  | fluffy
  | findlink
  | msrbot
  | panscient
  | yacybot
  | AISearchBot
  | ips-agent
  | tagoobot
  | MJ12bot
  | woriobot
  | yanga
  | buzzbot
  | mlbot
  | yandex\.com\/bots
  | purebot
  | Linguee[ ]Bot
  | CyberPatrol
  | voilabot
  | Baiduspider
  | citeseerxbot
  | spbot
  | twengabot
  | postrank
  | Turnitin
  | scribdbot
  | page2rss
  | sitebot
  | linkdex
  | Adidxbot
  | ezooms
  | dotbot
  | Mail\.RU_Bot
  | discobot
  | heritrix
  | findthatfile
  | europarchive\.org
  | NerdByNature\.Bot
  | (sistrix|SISTRIX)[ ][cC]rawler
  | Ahrefs(Bot|SiteAudit)
  | fuelbot
  | ^CrunchBot
  | IndeedBot
  | mappydata
  | woobot
  | ZoominfoBot
  | PrivacyAwareBot
  | Multiviewbot
  | SWIMGBot
  | Grobbot
  | eright
  | Apercite
  | semanticbot
  | Aboundex
  | domaincrawler
  | wbsearchbot
  | summify
  | CCBot
  | edisterbot
  | SeznamBot
  | ec2linkfinder
  | gslfbot
  | aiHitBot
  | intelium_bot
  | facebookexternalhit
  | Yeti
  | RetrevoPageAnalyzer
  | lb-spider
  | Sogou
  | lssbot
  | careerbot
  | wotbox
  | wocbot
  | ichiro
  | DuckDuckBot
  | lssrocketcrawler
  | drupact
  | webcompanycrawler
  | acoonbot
  | openindexspider
  | gnam[ ]gnam[ ]spider
  | web-archive-net\.com\.bot
  | backlinkcrawler
  | coccoc
  | integromedb
  | content[ ]crawler[ ]spider
  | toplistbot
  | it2media-domain-crawler
  | ip-web-crawler\.com
  | siteexplorer\.info
  | elisabot
  | proximic
  | changedetection
  | arabot
  | WeSEE:Search
  | niki-bot
  | CrystalSemanticsBot
  | rogerbot
  | 360Spider
  | psbot
  | InterfaxScanBot
  | CC[ ]Metadata[ ]Scaper
  | g00g1e\.net
  | GrapeshotCrawler
  | urlappendbot
  | brainobot
  | fr-crawler
  | binlar
  | SimpleCrawler
  | Twitterbot
  | cXensebot
  | smtbot
  | bnf\.fr_bot
  | A6-Indexer
  | ADmantX
  | Facebot
  | OrangeBot\/
  | memorybot
  | AdvBot
  | MegaIndex
  | SemanticScholarBot
  | ltx71
  | nerdybot
  | xovibot
  | BUbiNG
  | Qwantify
  | archive\.org_bot
  | Applebot
  | TweetmemeBot
  | crawler4j
  | findxbot
  | S[eE][mM]rushBot
  | yoozBot
  | lipperhey
  | Y!J
  | Domain[ ]Re-Animator[ ]Bot
  | AddThis
  | Screaming[ ]Frog[ ]SEO[ ]Spider
  | MetaURI
  | Scrapy
  | Livelap[bB]ot
  | OpenHoseBot
  | CapsuleChecker
  | collection\@infegy\.com
  | IstellaBot
  | DeuSu\/
  | betaBot
  | Cliqzbot\/
  | MojeekBot\/
  | netEstate[ ]NE[ ]Crawler
  | SafeSearch[ ]microdata[ ]crawler
  | Gluten[ ]Free[ ]Crawler\/
  | Sonic
  | Sysomos
  | Trove
  | deadlinkchecker
  | Slack-ImgProxy
  | Embedly
  | RankActiveLinkBot
  | iskanie
  | SafeDNSBot
  | SkypeUriPreview
  | Veoozbot
  | Slackbot
  | redditbot
  | datagnionbot
  | Google-Adwords-Instant
  | adbeat_bot
  | WhatsApp
  | contxbot
  | pinterest\.com\/bot
  | electricmonk
  | GarlikCrawler
  | BingPreview\/
  | vebidoobot
  | FemtosearchBot
  | Yahoo[ ]Link[ ]Preview
  | MetaJobBot
  | DomainStatsBot
  | mindUpBot
  | Daum\/
  | Jugendschutzprogramm-Crawler
  | Xenu[ ]Link[ ]Sleuth
  | Pcore-HTTP
  | moatbot
  | KosmioBot
  | [pP]ingdom
  | AppInsights
  | PhantomJS
  | Gowikibot
  | PiplBot
  | Discordbot
  | TelegramBot
  | Jetslide
  | newsharecounts
  | James[ ]BOT
  | Bark[rR]owler
  | TinEye
  | SocialRankIOBot
  | trendictionbot
  | Ocarinabot
  | epicbot
  | Primalbot
  | DuckDuckGo-Favicons-Bot
  | GnowitNewsbot
  | Leikibot
  | LinkArchiver
  | YaK\/
  | PaperLiBot
  | Digg[ ]Deeper
  | ^dcrawl
  | Snacktory
  | AndersPinkBot
  | Fyrebot
  | EveryoneSocialBot
  | Mediatoolkitbot
  | Luminator-robots
  | ExtLinksBot
  | SurveyBot
  | NING\/
  | okhttp
  | Nuzzel
  | omgili
  | PocketParser
  | YisouSpider
  | um-LN
  | ToutiaoSpider
  | MuckRack
  | Jamie's[ ]Spider
  | AHC\/
  | NetcraftSurveyAgent
  | Laserlikebot
  | ^Apache-HttpClient
  | AppEngine-Google
  | Jetty
  | Upflow
  | Thinklab
  | Traackr\.com
  | Twurly
  | Mastodon
  | http_get
  | DnyzBot
  | botify
  | 007ac9[ ]Crawler
  | BehloolBot
  | BrandVerity
  | check_http
  | BDCbot
  | ZumBot
  | EZID
  | ICC-Crawler
  | ArchiveBot
  | ^LCC[ ]
  | filterdb\.iss\.net\/crawler
  | BLP_bbot
  | BomboraBot
  | Buck\/
  | Companybook-Crawler
  | Genieo
  | magpie-crawler
  | MeltwaterNews
  | Moreover
  | newspaper\/
  | ScoutJet
  | (^|[ ])sentry\/
  | StorygizeBot
  | UptimeRobot
  | OutclicksBot
  | seoscanners
  | Hatena
  | Google[ ]Web[ ]Preview
  | MauiBot
  | AlphaBot
  | SBL-BOT
  | IAS[ ]crawler
  | adscanner
  | Netvibes
  | acapbot
  | Baidu-YunGuanCe
  | bitlybot
  | blogmuraBot
  | Bot\.AraTurka\.com
  | bot-pge\.chlooe\.com
  | BoxcarBot
  | BTWebClient
  | ContextAd[ ]Bot
  | Digincore[ ]bot
  | Disqus
  | Feedly
  | Fetch\/
  | Fever
  | Flamingo_SearchEngine
  | FlipboardProxy
  | g2reader-bot
  | G2[ ]Web[ ]Services
  | imrbot
  | K7MLWCBot
  | Kemvibot
  | Landau-Media-Spider
  | linkapediabot
  | vkShare
  | Siteimprove\.com
  | BLEXBot\/
  | DareBoost
  | ZuperlistBot\/
  | Miniflux\/
  | Feedspot
  | Diffbot\/
  | SEOkicks
  | tracemyfile
  | Nimbostratus-Bot
  | zgrab
  | PR-CY\.RU
  | AdsTxtCrawler
  | Datafeedwatch
  | Zabbix
  | TangibleeBot
  | google-xrawler
  | axios
  | Amazon[ ]CloudFront
  | Pulsepoint[ ]
  | CloudFlare-AlwaysOnline
  | Cloudflare-Healthchecks
  | Cloudflare-Traffic-Manager
  | CloudFlare-Prefetch
  | Cloudflare-SSLDetector
  | https:\/\/developers\.cloudflare\.com\/security-center\/
  | Google-Structured-Data-Testing-Tool
  | WordupInfoSearch
  | WebDataStats
  | HttpUrlConnection
  | ZoomBot
  | VelenPublicWebCrawler
  | MoodleBot
  | jpg-newsbot
  | outbrain
  | W3C_Validator
  | Validator\.nu
  | W3C-checklink
  | W3C-mobileOK
  | W3C_I18n-Checker
  | FeedValidator
  | W3C_CSS_Validator
  | W3C_Unicorn
  | Google-PhysicalWeb
  | Blackboard
  | ICBot\/
  | BazQux
  | Twingly
  | Rivva
  | Experibot
  | awesomecrawler
  | Dataprovider\.com
  | GroupHigh\/
  | theoldreader\.com
  | AnyEvent
  | Uptimebot\.org
  | Nmap[ ]Scripting[ ]Engine
  | 2ip\.ru
  | Clickagy
  | Caliperbot
  | MBCrawler
  | online-webceo-bot
  | B2B[ ]Bot
  | AddSearchBot
  | Google[ ]Favicon
  | HubSpot
  | Chrome-Lighthouse
  | HeadlessChrome
  | CheckMarkNetwork\/
  | www\.uptime\.com
  | Streamline3Bot\/
  | serpstatbot\/
  | MixnodeCache\/
  | ^curl
  | SimpleScraper
  | RSSingBot
  | Jooblebot
  | fedoraplanet
  | Friendica
  | NextCloud
  | Tiny[ ]Tiny[ ]RSS
  | RegionStuttgartBot
  | Bytespider
  | Datanyze
  | Google-Site-Verification
  | TrendsmapResolver
  | tweetedtimes
  | NTENTbot
  | Gwene
  | SimplePie
  | SearchAtlas
  | Superfeedr
  | feedbot
  | UT-Dorkbot
  | Amazonbot
  | AmazonProductDiscovery
  | AmazonSellerInitiatedListing
  | SerendeputyBot
  | Eyeotabot
  | officestorebot
  | Neticle[ ]Crawler
  | SurdotlyBot
  | LinkisBot
  | AwarioSmartBot
  | AwarioRssBot
  | RyteBot
  | FreeWebMonitoring[ ]SiteChecker
  | AspiegelBot
  | NAVER[ ]Blog[ ]Rssbot
  | zenback[ ]bot
  | SentiBot
  | Domains[ ]Project\/
  | Pandalytics
  | VKRobot
  | bidswitchbot
  | tigerbot
  | NIXStatsbot
  | Atom[ ]Feed[ ]Robot
  | [Cc]urebot
  | PagePeeker\/
  | Vigil\/
  | rssbot\/
  | startmebot\/
  | JobboerseBot
  | seewithkids
  | NINJA[ ]bot
  | Cutbot
  | BublupBot
  | BrandONbot
  | RidderBot
  | Taboolabot
  | Dubbotbot
  | FindITAnswersbot
  | infoobot
  | Refindbot
  | BlogTraffic\/\d\.\d+[ ]Feed-Fetcher
  | SeobilityBot
  | Cincraw
  | Dragonbot
  | VoluumDSP-content-bot
  | FreshRSS
  | BitBot
  | ^PHP-Curl-Class
  | Google-Certificates-Bridge
  | centurybot
  | Viber
  | e\.ventures[ ]Investment[ ]Crawler
  | evc-batch
  | PetalBot
  | virustotal
  | (^|[ ])PTST\/
  | minicrawler
  | Cookiebot
  | trovitBot
  | seostar\.co
  | IonCrawl
  | Uptime-Kuma
  | Seekport
  | FreshpingBot
  | Feedbin
  | CriteoBot
  | Snap[ ]URL[ ]Preview[ ]Service
  | Better[ ]Uptime[ ]Bot
  | RuxitSynthetic
  | Google-Read-Aloud
  | Valve\/Steam
  | OdklBot\/
  | GPTBot
  | ChatGPT-User
  | OAI-SearchBot
  | YandexRenderResourcesBot\/
  | LightspeedSystemsCrawler
  | ev-crawler\/
  | BitSightBot\/
  | woorankreview\/
  | Google-Safety
  | AwarioBot
  | DataForSeoBot
  | Linespider
  | WellKnownBot
  | A[ ]Patent[ ]Crawler
  | StractBot
  | search\.marginalia\.nu
  | YouBot
  | Nicecrawler
  | Neevabot
  | BrightEdge[ ]Crawler
  | SiteCheckerBotCrawler
  | TombaPublicWebCrawler
  | CrawlyProjectCrawler
  | KomodiaBot
  | KStandBot
  | CISPA[ ]Webcrawler
  | MTRobot
  | hyscore\.io
  | AlexandriaOrgBot
  | 2ip[ ]bot
  | Yellowbrandprotectionbot
  | SEOlizer
  | vuhuvBot
  | INETDEX-BOT
  | Synapse
  | t3versionsBot
  | deepnoc
  | Cocolyzebot
  | hypestat
  | ReverseEngineeringBot
  | sempi\.tech
  | Iframely
  | MetaInspector
  | node-fetch
  | l9explore
  | python-opengraph
  | OpenGraphCheck
  | developers\.google\.com\/\+\/web\/snippet
  | SenutoBot
  | MaCoCu
  | NewsBlur
  | inoreader
  | NetSystemsResearch
  | PageThing
  | WordPress\/
  | PhxBot
  | ImagesiftBot
  | Expanse
  | InternetMeasurement
  | ^BW\/
  | GeedoBot
  | Audisto[ ]Crawler
  | PerplexityBot\/
  | [cC]laude[bB]ot
  | Monsidobot
  | GroupMeBot
  | Vercelbot
  | vercel-screenshot
  | facebookcatalog\/
  | meta-externalads\/
  | meta-externalagent\/
  | meta-externalfetcher\/
  | AcademicBotRTU
  | KeybaseBot
  | Lemmy
  | CookieHubScan
  | Hydrozen\.io
  | HTTP[ ]Banner[ ]Detection
  | SummalyBot
  | MicrosoftPreview\/
  | GeedoProductSearch
  | TikTokSpider
  | OnCrawl\/
  | sindresorhus\/got
  | CensysInspect\/
  | SBIntuitionsBot\/
  | sitebulb
  | YextBot\/
  | DatadogSynthetics
  | Google-Ads-Conversions
  | ObservePoint
  | Checkly
  | ALittle[ ]Client
  | AliyunSecBot
  | Claude-Web
  | anthropic-ai
  | Claude-User
  | Claude-SearchBot
  | Google-Extended
  | cohere-ai
  | Timpibot
  | SERankingBacklinksBot
  | CMSChecker
  | Wayback
  | Playwright
  | Puppeteer
  | Selenium
  | Nikto
  | sqlmap
  | ZmEu
  | masscan
  | WPScan
  | [aA]cunetix
  | Nessus
  | [dD]ir[Bb]uster
  | StatusCake
  | colly
  | [mM]echanize
  | air\.ai\/scanning
  | asnriskscorer
  | OICrawler
  | l9scan
  | SlaccaleBot
  | CustomAsyncHttpClient
  | ^HTTPie\/
  | Gemini-Deep-Research
  | Perplexity-User
  | PerplexityUser
  | meta-webindexer
  | DuckAssistBot
  | MistralAI-User
  | webzio
  | newsai\/
  | ^ArenaUnfurlBot
  | A360-Search
  | AASA-Bot
  | AccessStatus
  | Acquia[ ]optimize
  | ActiveComply
  | AdkernelTopicCrawler
  | AlertSite
  | AllAfrica
  | Amazing-SearchBot
  | Amazon-Bedrock-AgentCore-Browser
  | AmazonBuyForMe
  | Amzn-SearchBot
  | Amzn-User
  | Anchor[ ]Browser
  | Anomura
  | AP3A\.240617\.008
  | ApifyBot
  | ApifyWebsiteContentCrawler
  | Archive-It
  | artemis[ ]web[ ]reader
  | atlassian-bot
  | Attracta
  | AudigentAdBot
  | Authory
  | Automaton|Newsify[ ]Feed[ ]Fetcher
  | AwarioRendererBot
  | AzureAI-SearchBot
  | BestChange
  | bigsur\.ai
  | bl\.uk_lddc_bot
  | BlingERP
  | Blockaid
  | Bloglines
  | BlogVault
  | bluesky-domain-status-classifier
  | Bluesky\/
  | bne\.es_bot
  | Brightbot
  | BrowserBot-Observer
  | BufferLinkPreviewBot
  | Bugsnag
  | Buttondown
  | CapitalOneBot
  | CertChief
  | channable
  | Channel3Bot
  | Chirp|gotosocial
  | ClickUpLinkUnfurler
  | Cloudflare-AutoRAG
  | Cloudflare-Custom-Hostname-Verification
  | Cloudflare-Stream-Webhook
  | CloudflareRadarURLScanner
  | Cloudtrellis
  | [cC]ludo
  | Code\/1\.
  | Collapsify
  | ContextualBot[\s\S]*outcomes\.net
  | Convermax
  | cookie-maestro
  | CookieHubVerify
  | CookieYesbot
  | Crazy[ ]Egg
  | Current[\s\S]*RSS[ ]Reader
  | cypex\.ai\/scanning
  | DeepCrawl
  | DigiCert[ ]DCV
  | dlvr\.it
  | Dotcom-Monitor
  | DrataAutopilot
  | DreamHost[ ]Data[ ]Team
  | ds9
  | [ ]DVbot
  | EcoVadisSustainabilityBot
  | elmah\.io[ ]Uptime[ ]Monitoring
  | EvernoteRichLinkBot
  | EzLynx
  | EzoicBot
  | FacebookBot
  | FastDAST
  | Feeder[ ]\/
  | FeedFlow
  | FindFiles\.net
  | FirecrawlAgent
  | FyndSearchEngine-Crawler
  | FyndSearchEngine-ReCrawler
  | Goodreads
  | Google[ ]Trust[ ]Services
  | Google-Agent
  | Google-Gemini-CLI
  | Google-NotebookLM
  | GoogleAgent-Mariner
  | Greppr[ ]Web[ ]Crawler
  | Hardenize
  | HoneybadgerBot
  | IbouBot
  | imageSpider
  | Innologica
  | kagi-fetcher
  | Kangaroo[ ]Bot
  | Known[ ]Agent
  | KrawlerBot
  | laion-huggingface-processor
  | LinkCheckerBot
  | LinkupBot
  | LMArenaUnfurlBot
  | lyonl-asset-proxy
  | lyonl-crawler
  | MagiBot
  | MagpieRSS
  | mail\.ru
  | MailChimp
  | Manus-User
  | McontextualBot
  | Mediumbot-MetaTagFetcher
  | MetaIAB[ ]Facebook
  | MixrankBot
  | ModernizeBot
  | MontasticMonitor
  | NanoInteractive
  | NestDaddybot
  | Netcraft[ ]SSL[ ]Server[ ]Survey
  | Netcraft[ ]Web[ ]Server[ ]Survey
  | NetSeer[ ]crawler
  | Netumo|netumo
  | NewRelicSynthetics
  | NewsRoom\.BI
  | Nitro-
  | NitroBot
  | Noibu
  | NostoCrawlerBot
  | OneTrust
  | opencode-smartfetch
  | ;Owler
  | ParselySharesBot
  | PhindBot
  | PodchaserParser
  | Podimo
  | Poggio-Citations
  | productsup\.io\/crawler
  | qcbot
  | Qualys
  | Quora-Bot
  | Qwantbot
  | Qwarrybot
  | RSiteAuditor
  | RSS\.Social
  | Salesforce\.com
  | Scope3
  | scraping\@nytimes\.com
  | Scrubby
  | Scrunchbot
  | seo4ajax\.com
  | SequelWP
  | ServerDensity
  | ShapBot
  | ShortPixel
  | Silktide
  | SiteLock
  | SmarshBot
  | SMTnetPMBot
  | Software-Security-Research
  | SottopopNone
  | Spider[\s\S]*spider\.com
  | Splunk
  | StatusNestBacklinkSpider
  | stepstoneCrawlBot
  | TavilyBot
  | ThousandEyes
  | Trae\/
  | TwinAgent
  | uipbot
  | um-FC
  | um-IC
  | UptimeStatistics
  | Verispider
  | visionheight\.com\/scan
  | Watchbot[ ]monitoring[ ]robot
  | Watchful
  | weborama-fetcher
  | webspidermount
  | WepchSearchEngine
  | wknd-bot
  | WPMU[ ]DEV[ ]Hub
  | WTotem
  | XoviOnpageCrawler
  | yelpspider
  | ZanistaBot
  | ZoomInfo-
  | 7Siters
  | Accessible[ ]Web[ ]Bot
  | AtVowBot
  | Bibliotheque[ ]Nacional[ ]de[ ]France[ ]Crawler
  | Bling[ ]ERP
  | CDSCbot
  | Critical[ ]CSS[ ]Bot
  | CybaaBot
  | CyberFindCrawler
  | Dark[ ]Visitor
  | Determ
  | DNSScanner
  | Drupalbot
  | eMoney[ ]Advisor
  | everyfeed-spider
  | ExteContextCrawl
  | FediDB
  | FediIndex
  | FediList[ ]Agent
  | Fedineko
  | FedReporter[ ]Bot[ ]for[ ]FFIEC
  | Feedsearch[ ]Bot
  | Feedsearch-Crawler
  | fiperbot
  | FleebsBot
  | Fluid
  | Flyriverbot
  | Freshbot
  | Gaisbot
  | GenomeCrawlerd
  | HaloBot
  | IRLbot
  | kaikki\.org-digital-archive
  | kb\.dk_bot
  | Library[ ]Of[ ]Congress[ ]Web[ ]Archiving
  | MagnetmeBot
  | MatchorySearch
  | Minoru's[ ]Fediverse[ ]Crawler
  | MirrorWebCrawler
  | mithril-crawler
  | ModatScanner
  | NapBot
  | New[ ]York[ ]Times[ ]Newsgathering
  | NLUX_IAHarvester
  | NoahBot
  | PlagAwareBot
  | Rakuten[ ]Image[ ]extraction[ ]bot
  | ResearchBot
  | rss-is-dead\.lol[ ]web[ ]bot
  | seoLyt
  | SirdataBot
  | SitesOverPagesBot
  | SleepBot
  | Sosospider
  | Termly
  | TLS[ ]tester
  | trafilatura
  | UrlBeeBot
  | videootv[ ]Bot
  | vmcrawl
  | WadooBot
  | Website-info\.net-Robot
  | WebZIP
  | WikiDo
  | WOVN[ ]Crawler
  | YoudaoBot
  | ZyBorg
  | Aranet-SearchBot
  | crawl4ai
  | DeepSeekBot
  | iaskspider
  | KunatoCrawler
  | TerraCotta
  | ABEvalBot
  | blekkobot
  | br-crawler
  | BuddyBot
  | CapterraBot
  | carbon-umbrella-bot
  | caveman-hunter
  | Centro[ ]Ads\.txt[ ]Crawler
  | WISEbot
  | CodaBot
  | Corporama[ ]matcher
  | CyotekWebCopy
  | Datadog[ ]Agent
  | Dazzle[ ]BlueSky[ ]Bot
  | DominicBot
  | Dow[ ]Jones[ ]Searchbot
  | Download[ ]Ninja
  | EmailWolf
  | fedistatsCrawler
  | GoParserBot
  | gsa-crawler
  | HanaleiBot
  | NicheIndex
  | HeadOnlyScraper
  | HenkBot
  | Impact\.com[ ]Agent
  | Keydrop\.io
  | larbin
  | SENTINEL-LinkCheck
  | linko
  | LinkpadBot
  | lwp-trivial
  | Magus[ ]Bot
  | NaverBot
  | loopimprovements\.com
  | OpenTheBoxBot
  | OWLer-W
  | peer39_crawler
  | Pixalate\.com
  | Poduptime
  | Pomothy-Bot
  | PulsePoint-Crawler
  | rawweb-bot
  | semantic-visions
  | Sindup
  | SiteSucker
  | SpringserveBot
  | SQWatcher
  | Supabase[ ]Paired[ ]Crawler
  | sv-watchagent
  | Swiftbot
  | SynthesiBot
  | TaraGroup[ ]Intelligent[ ]Bot
  | Thinkbot
  | TSMbot
  | TSM-turingos
  | UGAResearchAgent
  | UrlSuMa\.de[ ]crawler
  | WanscannerBot
  | WebCapture
  | WebCopier
  | cognitiveseo\.com
  | Xing[ ]Bot
  | XML[ ]Sitemaps[ ]Generator
  | YandoriRSSBot
  | Zealbot
  | 008\/
  | monitoring360bot\/
  | AdagioBot
  | adbeat\.com
  | AdminLabs
  | advanced_crawler
  | Adventurer
  | AGAKIDSBOT
  | AgencyAnalyticsBot
  | AI2Bot
  | AkismetBot
  | alexa[ ]site[ ]audit
  | Algolia[ ]Crawler
  | alienfarm
  | allOrigins
  | AmazonAdBot
  | KendraBot
  | AppSiteAssociation
  | Aragog\/
  | Aranea
  | ArchiveBox
  | ArquivoBot
  | Arquivo-web-crawler
  | ArtemisBot
  | Asana\/
  | AudistoBot
  | Autoconfig[ ]Test[ ]from[ ]USTC
  | tracking-quality-spider
  | Bad[ ]Neighborhood[ ]Header[ ]Detector
  | BaiduAdsBot
  | BDBot\/
  | BeeperBot
  | BetterUptimeBot
  | BnFBot
  | BigUpDataBot
  | BinaryCanary
  | Bitbucket-Webhooks
  | bl\.uk_ldfc_bot
  | BlackDuck-FD
  | Blogtrottr
  | BlueskyPreviewBot
  | BoardGamePricesBot
  | BotPoke
  | BDFetch
  | Brandwatch
  | BraveBot
  | brokenlinkcheck\.com
  | BW\/
  | Bushbaby
  | Butterfly
  | rss-parser
  | CaliberBot
  | CapitalOneShopping
  | Catchpoint
  | centuryb\.o\.t9
  | CERT[ ]PL
  | certytags
  | ChargeBeeBot
  | Charlotte
  | ChatGLM-Spider
  | Chatwork[ ]LinkPreview
  | CheckHost
  | Goodzer
  | Chrome[ ]Privacy[ ]Preserving[ ]Prefetch[ ]Proxy
  | CirrusExplorer
  | CLASSLA-web
  | Clearscopebot
  | WorldBot
  | Cloudflare-Validator
  | cloudflare-csup
  | Cloudflare-Custom-Error-Page-Crawler
  | Cloudflare-Radar-Scanner
  | Cloudflare-SpeedTest
  | Cloudflare-Stream-Hook
  | cognitiveSEO[ ]Bot
  | cohere-training-data-crawler
  | CommaFeed
  | researchscan\.comsys\.rwth-aachen\.de
  | contentkingapp
  | CookieHub[ ]Bot
  | Cotoyogi
  | Coveobot
  | Crawlson
  | RepoLookoutBot
  | Criticalcss\.com
  | cron-job\.org
  | DnBCrawler
  | DMBrowser
  | DomCopBot
  | downnotifier\.com
  | DowntimeDetector\/
  | Dlc\/
  | Dratabot
  | EasyBib[ ]AutoCite
  | easybill-ImportManager
  | EasyCron\/
  | easyDNS[ ]Monitoring
  | EchoboxBot\/
  | Cronless
  | crusty\/
  | csirt\.cz
  | CXK_Bot
  | daumoa
  | DaspeedBot
  | Dead[ ]Link[ ]Checker
  | Deskyobot
  | Detectify
  | Devin
  | DF[ ]Bot
  | DingTalkBot-LinkService
  | Discourse[ ]Forum[ ]Onebox
  | Dmbot
  | SustainabilityCrawler
  | edansbot
  | EdgeWatch
  | Do[ ]Not[ ]Track[ ]Verifier
  | elmahio-uptimebot
  | eMoneyBot
  | EpivozCrawler
  | eRepublik\.tools
  | EvoUptimeBot
  | ExodusMovement
  | Ezgif
  | factset_spyderbot
  | FastmailUA
  | FDL[ ]Stats[ ]Bot
  | Fedicabot
  | FedReporterDataBot
  | Feed[ ]Image[ ]Audit
  | FeedBurner
  | feeder\.co
  | Feedpresso[ ]Content[ ]Index[ ]Bot
  | Feedwind
  | fidget-spinner-bot
  | FirmoGraph
  | FlipboardRSS
  | Foregenix
  | Freespoke\/
  | Friendly[ ]testing[ ]bot
  | friendly-spider
  | FriendlyCrawler\/
  | FullStoryBot\/
  | Funnelback
  | FuseonBot\/
  | Gabanzabot\/
  | gdnplus\.com
  | getthit\.com
  | GG[ ]PeekBot
  | Ghost[ ]Inspector
  | github-camo
  | GlobalWebSearch
  | Golfe\/
  | Google-Apps-Script
  | GoogleStackdriverMonitoring
  | GoogleAssociationService\/
  | GoogleImageProxy
  | GoogleProducer
  | Googlebot-IA\/
  | Google-Trust-Services\/
  | Google-Area120
  | Google-CloudVertexBot
  | GoogleAssociationService$
  | GoogleDocs
  | GoPay
  | GotSiteMonitor\.com
  | synthetic-monitoring-agent\/
  | Grammarly\/
  | gregcrawler
  | GroovinaAdsbot\/
  | Grover\/
  | GTmetrix
  | GuestpostsBot\/
  | Gulper[ ]Web[ ]Bot
  | Verity\/
  | HappyWing
  | harsilbot\/
  | HawaiiBot
  | hCardValidator
  | Hello[ ]World
  | HelloworkJobPostingBot\/
  | HetrixTools
  | HIFIBot\/
  | Hlidam\.to[ ]robot
  | Honeybadger[ ]Uptime[ ]Check
  | HostTracker\/
  | Hotjar
  | hstspreload-bot
  | Huckabot\/
  | Hype[ ]Machine\/
  | Web[ ]Screen[ ]Service[ ]By[ ]hyperhost
  | AdsBot-IAB
  | iAskBot\/
  | IBM[ ]Crawler
  | IFTTT\/
  | ImageFetcher\/
  | ImageMind
  | img2dataset
  | imgproxy\/
  | impendoom-bot\/
  | IndeedJobBot
  | Innguma\/
  | Instapaper\/
  | Integromat\/
  | intelx\.io_bot
  | internetVista[ ]monitor
  | Irokez\.cz[ ]monitoring
  | IsDownBot\/
  | ISSCyberRiskCrawler\/
  | iubenda-radar\/
  | UptimeBot\/
  | jetmon\/
  | jobswithgptcom-bot
  | Jumio
  | Kagibot\/
  | KangarooBot\/
  | KargoBot-Artemis
  | kazbtbot\/
  | keycdn-tools\/
  | keys-so-bot
  | kinsta-bot
  | Klaviyo\/
  | Kukei\.eu-Bot\/
  | LAC_IAHarvester
  | LastModBot\/
  | LegalMonster
  | Let's[ ]Encrypt
  | Level9SearchBot\/
  | loc\.gov\/programs\/web-archiving
  | LinerBot\/
  | LinkTiger
  | LinkAce\/
  | LinksIndexerBot\/
  | LinkWalker\/
  | LogicMonitor
  | LoomlyBot
  | Macrobondbot
  | MADBbot\/
  | Magellan
  | magicsearchdev\/
  | Magnet\.me-web\/
  | MainWP\/
  | Make\/
  | ManageWP
  | MarketGoo\/
  | MarketingMiner
  | dbot\)
  | Mattermost-Bot\/
  | Mavifinds
  | MB-LinkChecker
  | MedialogiaBot
  | MediaMonitoringBot\/
  | MediavineMetadataParser\/
  | Pywikibot\/
  | CentComBot\/
  | MergadoBot
  | Meta-ExternalHit\/
  | Metorik
  | MgidBot
  | Miniature\.io\/
  | mirrorweb\.com
  | MissinglettrBot\/
  | crawler_eb_germany
  | ModularConnector\/
  | Mollie[ ]HTTP[ ]client
  | Monibot
  | monitis[ ]-
  | MonitoRSS\/
  | MonSpark\/
  | montastic-monitor
  | MonTools\.com
  | MotoMinerBot\/
  | MRGbot\/
  | MxToolbox
  | my-tiny-bot
  | MyBot\/
  | nbertaupete95
  | NetAPI
  | NetpeakCheckerBot\/
  | NetShelter[ ]ContentScan
  | NETVIGIE
  | NewRelicbot\/
  | nyt_scraping
  | NewsNow\/
  | NLNZ_IAHarvester
  | NodePing
  | nomore404\.com[ ]robot
  | noorobot
  | Nooshub\/
  | Notabot
  | Novaact\/
  | Novellum
  | NsToolsBot\/
  | nvdorz
  | Odin;
  | Offline[ ]Explorer
  | OhDear\/
  | Omnisend\/
  | Online[ ]Domain[ ]Tools
  | WebCEO[ ]Online\/
  | OnlineOrNot\.com_bot
  | OpenGraph\.io\/
  | OpenRSS
  | OpenVAS
  | Owler[ ]\(ows\.eu
  | Operator\/
  | Orbbot\/
  | zebra-v2-bot
  | Orlo-LinkPreview\/
  | Cozi-iCalendar-FeedReader
  | OutsellURLValidator
  | Overcast\/
  | PRTGCloudBot\/
  | Pagespeed\/
  | PanguBot
  | Panopta
  | Paqlebot\/
  | parse\.ly[ ]scraper\/
  | PayPal\/
  | PDF24[ ]URL[ ]To[ ]PDF
  | PingAdmin\.Ru\/
  | pingping\.io\/
  | PlayStore-Google
  | Plesk[ ]screenshot[ ]bot
  | PocketCasts\/
  | Potions\/
  | PressEngineBot
  | PricedroneShoppingBot\/
  | PriEcoBot\/
  | PrintFriendly\.com
  | Pro-Sitemaps\/
  | ProbelySPDR\/
  | ProjectShield-UrlCheck
  | Blackbox[ ]Exporter\/
  | Protopage\/
  | PS_Daily\/
  | pulsetic\.com
  | PWABuilderHttpAgent
  | QualifiedBot\/
  | Quantcastbot\/
  | Rackspace[ ]Monitoring\/
  | rakutenusabot-image\/
  | top100\.rambler\.ru[ ]crawler
  | RankurBot\/
  | RavenCrawler\/
  | Readable\/
  | Recurly[ ]Webhooks\/
  | RED\/
  | Reelevant\/
  | remove\.bg\/
  | Retool\/
  | RetroListeCOM\/
  | RevvimGort\/
  | reward-gateway
  | Riddler[ ]\(http:\/\/riddler\.io
  | RobotsChecker\/
  | RSSAPI\/
  | rss2tg
  | RssReaderBot
  | s4a-probe-bot\/
  | SFDC-Callout\/
  | page-preview-tool
  | SandobaCrawler\/
  | Sansec[ ]Security[ ]Monitor\/
  | GIFTEDVISITOR[ ]SCAN
  | Schema-Markup-Validator
  | Scoop\.it\/
  | ScourRSSBot\/
  | ScrapeheroBot\/
  | screeenly-bot
  | SEBot-WA
  | Searcherweb
  | Searcherxweb
  | SearchExpress
  | SecurityHeaders
  | semaltbot\/
  | SendGrid[ ]Event[ ]API
  | SentryUptimeBot\/
  | seo-audit-check-bot\/
  | s4a\/
  | ClarityBot\/
  | SeoSiteCheckup
  | SeoulBot
  | SERPtimizerBot
  | Server[ ]Density[ ]Service[ ]Monitoring
  | ServerHunterSpider\/
  | SeznamHomepageCrawler\/
  | Shopify-Captain-Hook
  | Shortwave[ ]Image[ ]Fetcher
  | linkReader\/
  | Sidetrade[ ]indexer[ ]bot
  | ^Silk\/
  | SinceraSyntheticUser\/
  | Optimizer\)
  | Site24x7
  | SiteAuditBot\/
  | SiteCheck-sitecrawl
  | SiteScoreBot
  | SiteSearch360\/
  | SiteUptime\.com
  | Konturbot\/
  | SkroutzBot
  | SkyworkSpider
  | SlickBot\/
  | SmartologyBot\/
  | SnapURLPreview\/
  | SnapchatAds\/
  | Snipcart\/
  | solarwinds\/
  | Sora[ ]POS\/
  | SparkShipping
  | SparkPost
  | Spawning-AI
  | IDG\/EU
  | Specificfeeds
  | Spectate\/
  | SpiderLing
  | splash[ ]Version\/
  | Rigor\)
  | TwinWaveScanner
  | SSL[ ]Labs[ ]\(https:\/\/www\.ssllabs\.com
  | SSSSBot\/
  | Stape\/
  | StartpagePrivateImageProxy\/
  | Statabot\/
  | StatistikAustria\/
  | StatsDroneBot
  | Stripe\/
  | Sucuri
  | Svix-Webhooks\/
  | SwifteqLinkChecker
  | Swisscows
  | Datadog[ ]Synthetic
  | TactiScout\/
  | tchelebi\/
  | bitdiscovery
  | Test[ ]Certificate[ ]Info
  | Testcrawler
  | test-bot
  | TestLocally\/
  | TestURI
  | TextRazor
  | The[ ]Knowledge[ ]AI
  | TheInternetSearchx
  | thesis-research-bot
  | Trellis-Services
  | trentwil\.es
  | Trustly\/
  | TTD-Content
  | Tweakers
  | TwilioProxy\/
  | UASlinkChecker\/
  | hgfAlphaXCrawl\/
  | Unshorten\.It\!
  | updown\.io
  | Uptime\/
  | uptimedoctor
  | Uptimia
  | uptrends
  | Urlcheckr\/
  | URLSuMaBot
  | useeBookChecker\/
  | Vagabondo\/
  | VaultPress
  | videootvBot
  | VsuSearchSpider\/
  | vu-server-health-scanner\/
  | WARDBot\/
  | WebsiteOps
  | WatchMouse
  | Web[ ]Measure\/
  | Webflow
  | webgains-bot
  | webprosbot\/
  | websitepulse
  | WebSniffer\/
  | WSM\/
  | WebwikiBot\/
  | WEDOS[ ]OnLine
  | WhatsMyIP\.org
  | WhatWeb\/
  | Wheregoes\.com
  | wheresitup\.com\/
  | Citoid
  | WireReaderBot\/
  | ZoteroTranslationServer\/WMF
  | wmtips\.com\/
  | WordCountBot\/
  | Wordup-1
  | workona-favicon-service\/
  | Indy[ ]Library
  | WJHRO\/
  | WormlyBot
  | WovnCrawler\/
  | wowLink[ ]Crawler\/
  | WP[ ]Time[ ]Capsule
  | WPUmbrella
  | wpbot\/
  | WPMU[ ]DEV[ ]Broken[ ]Link[ ]Checker
  | WPMUDEV[ ]Uptime[ ]Monitor
  | WPSec\/
  | WRTNBot
  | abuse\.xmco\.fr
  | XY-Archive-Compliance
  | Yahoo[ ]Ad[ ]monitoring
  | YahooMailProxy
  | YahooCacheSystem
  | YLT[ ]Chrome
  | YokoyGroupAG\/
  | Yuuperbot
  | Zapier
  | Zendesk[ ]Webhook
  | Zombiebot\/
  | zzhbot
  | Penthouse[ ]Critical[ ]Path[ ]CSS[ ]Generator
  | Google-AdWords-Express
  | Notion\/
  | SSL[ ]Labs$
  | Skroutz[ ]ImageBot
  | Tumblr\/
  | upday\/
  | watchTowr
  | PRTG[ ]Network[ ]Monitor
  | GeedoShopProductFinder
  | WatchForBot
  | ListGemBot
  )
}x;

1;

__END__
=encoding utf-8

=head1 NAME

Sympa::WWW::Crawlers - Regular expression for User-Agent of web crawlers

=head1 DESCRIPTION

This module keeps definition of regular expressions used by Sympa software.

The regular expression is generated from the data provided by the
project below.

=head1 SEE ALSO

=over

=item *

Syntactic patterns of HTTP user-agents used by bots / robots / crawlers /
scrapers / spiders

L<https://github.com/monperrus/crawler-user-agents>

=back


=head1 HISTORY

Crawler detection feature of WWSympa was introduced on Sympa 5.4a.4
which derives information provided by L<http://www.useragentstring.com>.

On Sympa 6.2.74, it was replaced with regular expression matching
using information provided by crawler-user-agents project above.

=cut
