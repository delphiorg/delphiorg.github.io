import pandas as pd
import os
import re

# --- 1. Load the Data ---
print("--- Loading metadata.csv ---")
df = pd.read_csv('metadata.csv')
print("First 5 rows of the data:")
print(df.head())
print("\n" + "="*50 + "\n")


# --- 2. Analyze Tags ---
print("--- Analyzing Tags ---")
# Drop rows where tags are not specified (NaN) and ensure tags are strings
tags_df = df.dropna(subset=['tags'])
tags_df = tags_df[tags_df['tags'].str.len() > 0]
# Split the tags string into a list of tags, then explode the list into separate rows
tag_counts = tags_df['tags'].str.split(', ').explode().value_counts()
print("Top 40 Most Used Tags:")
print(tag_counts.head(40))
print("\n" + "="*50 + "\n")


# --- 3. Analyze Categories ---
print("--- Analyzing Categories ---")
categories_df = df.dropna(subset=['categories'])
categories_df = categories_df[categories_df['categories'].str.len() > 0]
category_counts = categories_df['categories'].str.split(', ').explode().value_counts()
print("Category Counts:")
print(category_counts)
print("\n" + "="*50 + "\n")


# --- 4. Example: Renaming a Tag (In-memory) ---
print("--- Example: Renaming 'podcast' to 'Audio podCast' (In Memory) ---")
# This is a non-destructive example. It shows which posts would be affected.
posts_with_podcast_tag = df[df['tags'].str.contains(r'\bpodcast\b', na=False, regex=True)] # Use regex=True for word boundary
print(f"Found {len(posts_with_podcast_tag)} posts with the 'podcast' tag.")

# To actually replace the tag in the DataFrame (not in the files yet):
# df_modified = df.copy() # Make a copy if you want to apply changes to a new DataFrame
# df_modified['tags'] = df_modified['tags'].str.replace(r'\bpodcast\b', 'Audio podCast', regex=True, na=False)
# print("After replacement (first 5 affected posts):")
# print(df_modified[df_modified['tags'].str.contains('Audio podCast', na=False)][['filename', 'tags']].head())
print("\n" + "="*50 + "\n")


# --- 5. Updating the Post Files (Conceptual) ---
print("--- Updating Post Files (Conceptual) ---")
print("The following code is a non-executable example of how you would run a script to update the files.")
print("It is commented out for safety. You would run this part manually after verifying your changes")
print("in a Jupyter Notebook or similar environment, and after backing up your posts!")
    
update_script_example = """
# import os
# import re
# 
# # IMPORTANT: BACKUP YOUR _posts DIRECTORY BEFORE RUNNING THIS!
# 
# # This is the DataFrame with your desired changes
# # For this example, we'll use the df_modified from the cell above, or your final 'df' after modifications
# # For demonstration, let's assume 'df' has your final desired tags.
# # final_df = df_modified if 'df_modified' in locals() else df
# 
# # --- Configuration for the update ---
# # Set this to True ONLY when you are ready to write changes to files
# WRITE_CHANGES_TO_FILES = False 
# # ------------------------------------
# 
# # Ensure the 'tags' column is treated as strings for consistent splitting
# final_df['tags'] = final_df['tags'].astype(str).replace('nan', '')
# 
# print(f"Preparing to process {len(final_df)} posts for updates...")
# 
# for index, row in final_df.iterrows():
#     filename = row['filename']
#     post_path = os.path.join('_posts', filename)
# 
#     if not os.path.exists(post_path):
#         print(f"WARNING: File not found: {post_path}. Skipping.")
#         continue
# 
#     with open(post_path, 'r', encoding='utf-8') as f:
#         content = f.read()
# 
#     # Regex to find the front matter and the tags block within it
#     # This regex is an example and might need to be adjusted based on your exact front matter structure
#     # It looks for the start of the front matter (---), captures everything until 'tags:',
#     # then captures the tags block (until the next key:value or end of front matter)
#     # and finally captures the rest of the front matter until the closing ---.
# 
#     # The tag block can be either a single line 'tags: tag1, tag2' or multi-line
#     # This regex is an improvement for handling multi-line tags list more robustly.
#     # It captures the part *before* tags, the tags block itself, and the part *after* tags.
# 
#     # Prepare new tags YAML string
#     new_tags_list = [tag.strip() for tag in row['tags'].split(',') if tag.strip()]
#     new_tags_yaml_block = 'tags:\n' + '\n'.join([f'  - {tag}' for tag in new_tags_list]) if new_tags_list else ''
# 
#     # Regex to find and replace the tags block in YAML front matter
#     # It assumes tags block is defined as 'tags:' followed by list items or inline array
#     # This might need fine-tuning for edge cases in your YAML front matter.
#     # Group 1: Everything before the 'tags:' key
#     # Group 2: The 'tags:' key itself (to preserve indentation of 'tags:')
#     # Group 3: The old tags block (list items or inline array)
#     # Group 4: Everything after the tags block until the end of front matter (---)
#     # This regex is highly dependent on your YAML structure.
# 
#     # More robust regex for tags block replacement:
#     # Matches the front matter content between the --- delimiters
#     front_matter_pattern = re.compile(r'(^---\s*$\n)(.*?)(^---\s*$)', re.MULTILINE | re.DOTALL)
#     front_matter_match = front_matter_pattern.search(content)
# 
#     if front_matter_match:
#         fm_start = front_matter_match.group(1) # '---' start
#         fm_content = front_matter_match.group(2) # Content of front matter
#         fm_end = front_matter_match.group(3) # '---' end
# 
#         # Regex to find 'tags:' line and subsequent list items or inline array
#         # This version tries to be more robust by matching until the next key or end of front matter content
#         tags_block_pattern = re.compile(r'(^\s*tags:)(.*?)(^\s*\w+:|\n---)', re.MULTILINE | re.DOTALL)
#         tags_block_match = tags_block_pattern.search(fm_content)
# 
#         if tags_block_match:
#             # Tags block found, replace it
#             before_tags = fm_content[:tags_block_match.start(1)]
#             after_tags = fm_content[tags_block_match.end(3) - (len(tags_block_match.group(3)) if tags_block_match.group(3).startswith('\n') else 0):] # Adjust end to include the next key if matched
#             if tags_block_match.group(3) and not tags_block_match.group(3).strip().startswith('---'):
#                 after_tags = tags_block_match.group(3) + after_tags # Add the next key back
# 
#             new_fm_content = before_tags.strip() + '\n' + new_tags_yaml_block + '\n' + after_tags.strip()
# 
#         elif new_tags_list: # No tags block found, but new tags exist, so insert it before the closing --- of front matter
#             # Find the last key:value pair in the front matter and insert after it
#             last_key_pattern = re.compile(r'(^\s*\w+:\s*.*?)(?:\n---|\n\s*\w+:)', re.MULTILINE | re.DOTALL)
#             last_key_match = None
#             for m in last_key_pattern.finditer(fm_content):
#                 last_key_match = m
# 
#             if last_key_match:
#                 insert_point = last_key_match.end(0)
#                 new_fm_content = fm_content[:insert_point].strip() + '\n' + new_tags_yaml_block + '\n' + fm_content[insert_point:].strip()
#             else:
#                 # Fallback: just append before the end of front matter
#                 new_fm_content = fm_content.strip() + '\n' + new_tags_yaml_block
# 
#         else:
#             # No tags block, and no new tags to add
#             new_fm_content = fm_content
# 
#         updated_content = fm_start + new_fm_content.strip() + '\n' + fm_end
# 
#         if WRITE_CHANGES_TO_FILES:
#             with open(post_path, 'w', encoding='utf-8') as f:
#                 f.write(updated_content)
#             print(f"Updated {filename}")
#         else:
#             print(f"Would update {filename} (WRITE_CHANGES_TO_FILES is False)")
#     else:
#         print(f"Could not find front matter in {filename}. Skipping.")
# 
# print("File update process complete (conceptual).")
