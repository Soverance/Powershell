CREATE DATABASE [soverance.com];
GO

USE [soverance.com];
GO

CREATE TABLE [Category] (
    [CategoryId] int NOT NULL IDENTITY,
    [CategoryName] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_Category] PRIMARY KEY ([CategoryId])
);
GO

CREATE TABLE [Post] (
    [PostId] int NOT NULL IDENTITY,
    [CategoryId] int NOT NULL,    
    [PostType] int NOT NULL, 
    [Slug] nvarchar(max),
    [Date] nvarchar(max),    
    [Title] nvarchar(max),
    [Description] nvarchar(max),
	[Content] nvarchar(max),
    [Author] nvarchar(max),
    [VideoUrl] nvarchar(max),
    [Slider1] nvarchar(max),
    [Slider2] nvarchar(max),
    [Slider3] nvarchar(max),
    [PlaylistId] nvarchar(max),
    CONSTRAINT [PK_Post] PRIMARY KEY ([PostId]),
    CONSTRAINT [FK_Post_Category_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [Category] ([CategoryId]) ON DELETE CASCADE
);
GO

INSERT INTO [Category] (CategoryName) VALUES
('General'),
('Portfolio'),
('Tutorials'),
('Motorcycles'),
('Ethereal Legends'),
('Endless Reach')
GO