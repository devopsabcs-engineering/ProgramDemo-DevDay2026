#!/usr/bin/env python3
"""Clean up example program markdown files - remove double-spacing, preserve UTF-8."""
import re
import os

DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(os.path.join(DIR, 'assets', 'example-programs'))

def format_letter(lines):
    """Take content-only lines (no blanks) and insert blank lines at section boundaries."""
    result = []
    n = len(lines)
    
    for i, line in enumerate(lines):
        # Determine if we need a blank line BEFORE this line
        if i > 0:
            prev = lines[i - 1]
            need_blank = False
            
            # After phone/telephone line
            if re.search(r'Phone:|T[eé]l[eé]phone', prev, re.IGNORECASE):
                need_blank = True
            
            # After date line
            if re.match(r'^(September|October|November|December|Le \d+)', prev):
                need_blank = True
            
            # After ministry city line (Toronto with postal code)
            if re.match(r'^Toronto', prev) and ('ON' in prev or 'Ontario' in prev):
                need_blank = True
            
            # After Subject/Objet line
            if prev.startswith('Subject:') or prev.startswith('Objet :'):
                need_blank = True
            
            # After greeting line
            if prev in ('Dear Sir or Madam,', 'Madame, Monsieur,'):
                need_blank = True
            
            # Before section headers (**)
            if line.startswith('**'):
                need_blank = True
            
            # Before closing paragraph patterns
            closing_starts = [
                'In summary,', 'In conclusion,', 'In closing,',
                'En résumé,', 'En conclusion,',
                'I appreciate', 'Je vous remercie de l\'attention',
                'Je vous remercie de votre',
            ]
            for cs in closing_starts:
                if line.startswith(cs):
                    need_blank = True
            
            # Before sign-off
            if line == 'Sincerely,' or line.startswith('Veuillez agréer'):
                need_blank = True
            
            # Before [Signature]
            if line == '[Signature]':
                need_blank = True
            
            # Before final name (last line)
            if i == n - 1:
                need_blank = True
            
            if need_blank:
                result.append('')
        
        result.append(line)
    
    return result


def process_file(filename):
    """Read a file, strip blanks, reformat, write back."""
    with open(filename, 'r', encoding='utf-8') as f:
        raw_lines = [line.rstrip() for line in f.readlines()]
    
    # Remove all blank lines
    content = [line for line in raw_lines if line.strip()]
    
    # Special handling for health_en.md: remove header lines
    if filename == 'health_en.md':
        # Remove lines before the sender name (lines starting with "Health:" or "English Submission:")
        while content and (content[0].startswith('Health:') or content[0].startswith('English Submission')):
            content.pop(0)
    
    # Format as letter
    formatted = format_letter(content)
    
    # Write back
    with open(filename, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(formatted) + '\n')
    
    print(f"  {filename}: {len(raw_lines)} raw -> {len(content)} content -> {len(formatted)} formatted")


# Process all files except education_en.md (already clean) and education_fr.md (needs reconstruction)
files_to_process = [
    'environment_en.md', 'environment_fr.md',
    'health_en.md', 'health_fr.md',
    'infrastructure_en.md', 'infrastructure_fr.md',
    'social_services_en.md', 'social_services_fr.md',
]

print("Processing files:")
for f in files_to_process:
    process_file(f)

# Now reconstruct education_fr.md with proper accents
print("\nReconstructing education_fr.md with proper accents...")
education_fr_content = """Marie Leblanc
256, avenue Notre-Dame
Sudbury (Ontario) P3C 5L5
Courriel : marie.leblanc@example.com
Téléphone : 705-555-9876

Le 20 septembre 2026

Ministère de l'Éducation
14e étage, 315 rue Front Ouest
Toronto (Ontario) M7A 0B8

Objet : Proposition d'un programme de tutorat et de mentorat parascolaire

Madame, Monsieur,

En tant que parent et membre du conseil d'école dans le Nord de l'Ontario, je vous écris pour proposer un « Programme de tutorat et de mentorat parascolaire » afin d'aider les élèves qui rencontrent des difficultés académiques, notamment en lecture et en mathématiques. La pandémie et d'autres défis ont creusé les écarts d'apprentissage pour de nombreux élèves, en particulier ceux issus de milieux marginalisés ou à faible revenu. Ce programme fournirait un soutien scolaire supplémentaire et des opportunités de mentorat aux élèves en dehors des heures de classe, pour les aider à combler leurs retards et à exceller dans leurs études.

**Description du programme proposé :**
Le Programme de tutorat et de mentorat parascolaire serait mis en œuvre dans les écoles élémentaires et secondaires publiques à travers l'Ontario, en ciblant tout particulièrement les écoles dont les résultats aux tests standardisés ou les taux de diplomation révèlent un besoin accru de soutien. Le programme recruterait des tuteurs qualifiés (par exemple des enseignants à la retraite, des étudiants en éducation ou des bénévoles de la communauté) pour offrir gratuitement ou à faible coût du tutorat en petits groupes ou individuel dans les matières de base comme la lecture, l'écriture, les mathématiques et les sciences. De plus, il jumellerait les élèves avec des mentors — notamment des élèves plus âgés, des membres de la communauté ou des professionnels — qui offriraient des conseils, de l'aide aux devoirs et des encouragements. Le programme pourrait être financé grâce à une collaboration entre le ministère de l'Éducation et les conseils scolaires, avec le soutien potentiel d'organismes communautaires ou de commandites d'entreprises pour fournir du matériel pédagogique et des collations aux participants.

**Objectifs :**
- Améliorer les compétences en littératie et en numératie chez les élèves dont le rendement est inférieur aux normes provinciales ou qui ont pris du retard à cause de perturbations (comme celles causées par la pandémie de COVID-19).
- Accroître la confiance et la motivation des élèves à l'école en leur offrant un soutien personnalisé et des modèles positifs grâce au mentorat.
- Réduire les écarts de réussite liés au statut socio-économique, en veillant à ce que tous les élèves aient la possibilité de réussir, peu importe leur milieu ou les ressources de leur famille.

**Résultats escomptés :**
- Des notes plus élevées et de meilleurs résultats aux évaluations en classe pour les élèves participants, comme en témoigne l'amélioration de leurs bulletins scolaires et de leurs scores aux évaluations standardisées en lecture et en mathématiques.
- Une meilleure assiduité scolaire et des taux de diplomation accrus dans les écoles qui mettent en place le programme, les élèves en difficulté étant plus engagés et plus confiants dans leurs capacités.
- Un mieux-être social et émotionnel renforcé chez les élèves, les jeunes bénéficiant du mentorat faisant état d'une motivation, d'une estime de soi et d'aspirations accrues pour leurs études postsecondaires ou leur future carrière.

**Justification du soutien gouvernemental :**
Investir dans l'éducation et la réussite des élèves apporte des avantages à long terme pour notre société et notre économie. Lorsqu'on offre aux élèves le soutien dont ils ont besoin dès le début, ils sont moins susceptibles de prendre davantage de retard, de décrocher ou d'avoir besoin plus tard de mesures de rattrapage coûteuses. Ce programme s'aligne sur le mandat du ministère, qui est d'améliorer le rendement des élèves et d'assurer l'équité des résultats scolaires pour tous. De nombreuses familles des régions rurales ou à faible revenu n'ont pas les moyens d'offrir des cours particuliers à leurs enfants ; un programme public de tutorat parascolaire contribuerait donc à égaliser les chances. En outre, faire appel à des bénévoles de la communauté et à des élèves plus âgés comme mentors favorisera un fort sentiment d'appartenance communautaire et d'engagement civique. Ce programme aiderait non seulement les élèves sur le plan scolaire, mais il contribuerait également à former de futurs enseignants et leaders en offrant aux bénévoles et aux jeunes mentors une expérience concrète de l'enseignement et du leadership.

En résumé, j'exhorte le gouvernement de l'Ontario à adopter le Programme de tutorat et de mentorat parascolaire pour aider nos élèves à s'épanouir. En offrant un soutien scolaire supplémentaire et un mentorat personnalisés, nous pourrons combler les retards d'apprentissage, promouvoir l'équité en éducation et permettre à la prochaine génération d'atteindre son plein potentiel. Je vous remercie de l'attention portée à cette proposition. Je me tiens à votre disposition pour discuter plus avant de cette idée et répondre à toute question que vous pourriez avoir.

Veuillez agréer, Madame, Monsieur, mes salutations distinguées.

[Signature]

Marie Leblanc
"""

with open('education_fr.md', 'w', encoding='utf-8', newline='\n') as f:
    f.write(education_fr_content.lstrip('\n'))

print("  education_fr.md: reconstructed with proper accents")
print("\nDone! All 10 files cleaned.")
