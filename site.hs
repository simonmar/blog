--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" allContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            -- Used by the RSS/Atom feed
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "pages/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/page.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls
    
    match "bib/*.md" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/page.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls
    
    match "bib/*.bib" $ do
        route   idRoute
        compile copyFileCompiler

    -- http://jaspervdj.be/hakyll/tutorials/05-snapshots-feeds.html
    let rss name render' =
          create [name] $ do
              route idRoute
              compile $ do
                  let feedCtx = postCtx `mappend` bodyField "description"
                  posts <- fmap (take 10) . recentFirst =<< loadAllSnapshots "posts/*" "content"
                  render' feedConfiguration feedCtx posts

    rss "atom.xml" renderAtom

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    allContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    allContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    allContext

allContext =
   field "siteTitle" (\_ -> return "Simon Marlow") `mappend`
   field "baseurl" (\_ -> return "") `mappend`
   dateField "date" "%B %e, %Y" `mappend`
   defaultContext

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
   { feedTitle       = "Simon Marlow"
   , feedDescription = ""
   , feedAuthorName  = "Simon Marlow"
   , feedAuthorEmail = "marlowsd@gmail.com"
   , feedRoot        = "https://simonmar.github.io"
   }
