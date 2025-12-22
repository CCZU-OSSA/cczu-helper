-- 0001_init.sql
-- Create basic tables for Teahouse: profiles, categories, posts, comments, likes

-- Enable extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Profiles (basic)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text,
  avatar_url text,
  bio text,
  created_at timestamptz DEFAULT now()
);

-- Categories for posts
CREATE TABLE IF NOT EXISTS categories (
  id serial PRIMARY KEY,
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Posts table
CREATE TABLE IF NOT EXISTS posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  category_id integer REFERENCES categories(id) ON DELETE SET NULL,
  image_urls text,
  price numeric,
  is_anonymous boolean DEFAULT false,
  status text DEFAULT 'available',
  created_at timestamptz DEFAULT now()
);

-- Comments table
CREATE TABLE IF NOT EXISTS comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
  user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  parent_comment_id uuid REFERENCES comments(id) ON DELETE SET NULL,
  content text NOT NULL,
  is_anonymous boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Likes table (to support like/unlike)
CREATE TABLE IF NOT EXISTS likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (post_id, user_id)
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_post_id_created_at ON comments (post_id, created_at ASC);

-- RPC: get posts with like counts and whether a given user liked each post
CREATE OR REPLACE FUNCTION public.get_posts_with_likes(p_limit integer, p_offset integer, p_user uuid)
RETURNS TABLE(
  id uuid,
  category_id integer,
  title text,
  content text,
  created_at timestamptz,
  image_urls text,
  is_anonymous boolean,
  price numeric,
  status text,
  user_id uuid,
  like_count integer,
  is_liked boolean
)
LANGUAGE sql STABLE
AS $$
  SELECT
    p.id,
    p.category_id,
    p.title,
    p.content,
    p.created_at,
    p.image_urls,
    p.is_anonymous,
    p.price,
    p.status,
    p.user_id,
    coalesce(lc.cnt, 0) AS like_count,
    CASE WHEN p_user IS NULL THEN false ELSE EXISTS(SELECT 1 FROM likes l2 WHERE l2.post_id = p.id AND l2.user_id = p_user) END AS is_liked
  FROM posts p
  LEFT JOIN (
    SELECT post_id, count(*) AS cnt FROM likes GROUP BY post_id
  ) lc ON lc.post_id = p.id
  ORDER BY p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
$$;

