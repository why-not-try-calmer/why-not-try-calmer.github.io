--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Data.Monoid (mappend)
import Hakyll

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith siteConfig $ do
  match "images/*" $ do
    route idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  match (fromList ["about.rst", "contact.markdown"]) $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

  match "posts/*" $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= saveSnapshot "content"
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls
    makeFeed

  create ["archive.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let archiveCtx =
            listField "posts" postCtx (return posts)
              `mappend` constField "title" "Archives"
              `mappend` defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
        >>= loadAndApplyTemplate "templates/default.html" archiveCtx
        >>= relativizeUrls

  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let indexCtx =
            listField "posts" postCtx (return posts)
              `mappend` defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    `mappend` defaultContext

feedConfig :: FeedConfiguration
feedConfig =
  FeedConfiguration
    { feedTitle = "Why Not Try Calmer: Blog"
    , feedDescription = "Just an ordinary blog"
    , feedAuthorName = "Adrien Glauser"
    , feedAuthorEmail = "adrien.glauser@gmail.com"
    , feedRoot = "https://why-not-try-calmer.github.io"
    }

makeFeed :: Rules ()
makeFeed = create ["feed.xml"] $ do
  route idRoute
  compile $ do
    let feedCtx = postCtx `mappend` bodyField "description"
    posts <- fmap (take 20) . recentFirst =<< loadAllSnapshots "posts/*" "content"
    renderRss feedConfig feedCtx posts

siteConfig :: Configuration
siteConfig = defaultConfiguration{destinationDirectory = "docs"}
