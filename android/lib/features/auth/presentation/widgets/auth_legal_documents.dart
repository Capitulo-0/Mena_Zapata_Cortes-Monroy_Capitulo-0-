import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Los textos se versionan junto al consentimiento enviado a Neon.
/// Revisión legal y datos de contacto del responsable pendientes antes de publicar.
enum LegalDocument { terms, privacy }

class AuthLegalConsentCheckbox extends StatelessWidget {
  const AuthLegalConsentCheckbox({
    super.key,
    required this.value,
    required this.title,
    required this.document,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final LegalDocument document;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.goldOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: value,
          activeColor: gold,
          checkColor: AppColors.backgroundOf(context),
          side: BorderSide(color: gold, width: 1.6),
          onChanged: (next) => onChanged(next ?? false),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'He leído y acepto los ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              InkWell(
                onTap: () => showLegalDocument(context, document),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: gold,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: gold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> showLegalDocument(BuildContext context, LegalDocument document) {
  final isTerms = document == LegalDocument.terms;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceOf(dialogContext),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isTerms ? 'Términos y condiciones' : 'Política de privacidad',
        style: GoogleFonts.cinzel(
          color: AppColors.deepOf(dialogContext),
          fontWeight: FontWeight.w700,
          fontSize: 19,
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: SelectableText(
            isTerms ? _terms : _privacy,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.55,
              color: AppColors.textPrimaryOf(dialogContext),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            'Cerrar',
            style: TextStyle(color: AppColors.goldOf(dialogContext)),
          ),
        ),
      ],
    ),
  );
}

const _terms = '''CAPÍTULO 0 — TÉRMINOS Y CONDICIONES
Versión: 2026-11-20

1. OBJETO DEL SERVICIO
Capítulo 0 es una comunidad digital para descubrir libros, registrar lecturas, participar en espacios lectores y crear y leer historias. Estas condiciones regulan el uso de la aplicación, sus perfiles, funciones de Biblioteca, Writer, clubes y puntos lectores.

2. CUENTA Y ACCESO
Para las funciones personales debes crear una cuenta y facilitar información correcta. La autenticación se realiza mediante Firebase Authentication, incluyendo inicio de sesión con correo o Google cuando esté disponible. Debes proteger tus credenciales, evitar compartir el acceso y avisar al equipo responsable de usos no autorizados por los canales oficiales que se publiquen en la aplicación. Las personas que utilicen la aplicación deben tener capacidad legal suficiente; las condiciones aplicables a menores de edad requieren revisión y medidas específicas antes del lanzamiento público.

3. PERFILES Y COMUNIDAD
Tu nombre de usuario, nombre visible, biografía, avatar y publicaciones pueden ser visibles para otras personas según las opciones de privacidad y acceso de la aplicación. Debes respetar a los demás usuarios. No se permite acosar, amenazar, suplantar identidades, difundir información privada ajena ni manipular seguidores, reseñas o interacciones.

4. BIBLIOTECA, RESEÑAS Y CLUBES
Puedes organizar tus libros, registrar avances, reseñas, favoritos y metas lectoras, y participar en clubes cuando la función esté disponible. Las opiniones y publicaciones son responsabilidad de quien las emite. La información sobre libros y puntos de interés puede proceder de servicios externos y puede cambiar o contener errores.

5. WRITER Y CONTENIDO CREADO
Conservas los derechos que te correspondan sobre las historias y contenidos originales que publiques. Al publicarlos otorgas a Capítulo 0 una autorización no exclusiva y limitada a almacenar, procesar y mostrar esos contenidos dentro del servicio según tus decisiones de publicación y privacidad. No debes subir contenido que infrinja derechos de autor o derechos de terceros. No puedes atribuirte obras ajenas ni publicar material ilícito.

6. NORMAS DE USO
No se permite utilizar la aplicación para actividades ilegales, ataques informáticos, distribución de malware, extracción abusiva de datos ni envío masivo de mensajes no deseados. Los contenidos contrarios a estas reglas podrán quedar sujetos a medidas de moderación proporcionadas, según los mecanismos disponibles y la legislación aplicable.

7. SERVICIOS EXTERNOS Y UBICACIÓN
Algunas funciones utilizan datos de terceros (como catálogos bibliográficos, mapas y servicios de identidad). Los puntos lectores cercanos requieren acceder a información de ubicación cuando la persona lo autoriza a través del dispositivo. La disponibilidad, calidad y exactitud de estos servicios no están garantizadas.

8. DISPONIBILIDAD Y CAMBIOS
El servicio puede necesitar mantenimiento, mejoras o interrupciones. Los cambios sustanciales a estos términos deben informarse y, cuando corresponda, solicitar una nueva aceptación antes de aplicar condiciones actualizadas.

9. PRIVACIDAD Y PROTECCIÓN DE DATOS
El tratamiento de información personal se explica separadamente en la Política de privacidad. Aceptar estos términos no equivale a autorizar usos opcionales de datos personales que legalmente requieran un consentimiento distinto.

10. LEGISLACIÓN APLICABLE
Las actividades de Capítulo 0 deberán ajustarse a la legislación aplicable, incluyendo la normativa chilena de protección de datos personales y propiedad intelectual cuando resulte pertinente. Ninguna disposición pretende limitar derechos irrenunciables de las personas usuarias.

AVISO PREVIO AL LANZAMIENTO: Este borrador debe ser validado por el responsable legal de Capítulo 0, incluyendo su identificación, domicilio, contacto, reglas para menores, moderación y mecanismos de reclamo.''';

const _privacy = '''CAPÍTULO 0 — POLÍTICA DE PRIVACIDAD
Versión: 2026-11-20

1. RESPONSABLE Y ALCANCE
Esta política describe el tratamiento de datos en Capítulo 0. Antes de publicar el servicio debe identificarse expresamente a la persona natural o jurídica responsable, con un canal válido para consultas y ejercicio de derechos. La presente versión es un borrador pendiente de esa identificación.

2. INFORMACIÓN DE CUENTA
La aplicación utiliza identificador de Firebase, correo electrónico verificado, nombre visible, nombre de usuario y, según el uso, biografía, foto de perfil y ajustes de privacidad. Durante el formulario de registro se solicita fecha de nacimiento y género; en el flujo de registro revisado estos dos valores se emplean en la interfaz y no se envían actualmente al servicio de creación del usuario en Neon. Debe verificarse y documentarse cualquier tratamiento adicional si se incorpora posteriormente.

3. DATOS DE LECTURA Y ACTIVIDAD
Según las funciones utilizadas pueden tratarse libros agregados, estados y progresos de lectura, reseñas, favoritos, metas anuales, estados lectores, clubes, solicitudes de seguimiento, notificaciones, historias, capítulos y publicaciones de Writer. Estas operaciones permiten mantener tu experiencia y los contenidos que decidas compartir con la comunidad.

4. UBICACIÓN Y PUNTOS LECTORES
La función de puntos lectores cercanos puede requerir acceso a la ubicación de tu dispositivo. Debe funcionar de acuerdo con los permisos concedidos y utilizar los datos necesarios para calcular cercanía y mostrar mapas. La información relacionada con caché local y eventuales llamadas a servicios de mapas debe revisarse de acuerdo con la configuración del entorno publicado. No se debe afirmar que se guarda un historial de ubicación si ello no está implementado.

5. FINALIDADES DEL TRATAMIENTO
Los datos se usan para autenticar y mantener cuentas, recuperar sesiones, mostrar perfiles según su visibilidad, ofrecer funciones lectoras y de creación, gestionar seguidores, clubes, contenidos y notificaciones, proteger la seguridad del servicio y registrar la aceptación de los documentos legales. No se autoriza automáticamente el uso publicitario de información personal por aceptar esta política.

6. PROVEEDORES Y TRANSFERENCIAS
Firebase Authentication gestiona la autenticación. Neon/PostgreSQL almacena datos del servicio; determinadas integraciones de mapas, catálogos de libros, imágenes y recomendaciones pueden comunicar información necesaria a sus respectivos proveedores. La ubicación geográfica de los servidores, países destinatarios, contratos y bases jurídicas de transferencias internacionales deben verificarse y detallarse antes del lanzamiento público. Los proveedores aplican también sus propias políticas.

7. VISIBILIDAD Y ELECCIONES
Algunos datos del perfil y contenidos publicados pueden ser visibles según la configuración pública o privada y las relaciones de seguimiento. Los controles de privacidad no impiden que otras personas con acceso legítimo hayan visto contenidos previamente. La aplicación debe respetar las restricciones de acceso implementadas en el backend.

8. CONSENTIMIENTO Y REGISTRO DE ACEPTACIÓN
Para cuentas nuevas se registran por separado las fechas y versiones aceptadas de los Términos y condiciones y de esta Política de privacidad. Las cuentas anteriores a este mecanismo no se marcan retroactivamente como si hubieran consentido. La base jurídica para cada finalidad del tratamiento debe determinarse de acuerdo con la legislación vigente; la aceptación de una política no sustituye los consentimientos específicos que puedan resultar necesarios.

9. CONSERVACIÓN Y SEGURIDAD
Los datos se conservan durante el tiempo necesario para prestar el servicio y cumplir obligaciones aplicables. Deben definirse y publicarse plazos y mecanismos concretos para conservación, supresión, copias de seguridad y respuesta a incidentes. Se utilizan autenticación y controles de acceso, pero ningún sistema puede prometer seguridad absoluta.

10. DERECHOS DE LAS PERSONAS
Conforme a la legislación aplicable puedes solicitar información, acceso, rectificación, supresión, oposición, bloqueo y portabilidad cuando proceda. Antes del lanzamiento se debe indicar el canal de contacto del responsable y un procedimiento para tramitar estas solicitudes. En Chile la Ley 21.719 incorpora un nuevo marco de protección de datos desde el 1 de diciembre de 2026.

11. MENORES Y DATOS SENSIBLES
Los datos relacionados con menores de edad y determinadas categorías de información requieren especial protección. Antes de habilitar el registro público deben revisarse la edad mínima, los mecanismos de autorización que correspondan y la necesidad de solicitar datos como el género.

12. ACTUALIZACIONES
Las modificaciones relevantes se comunicarán y, cuando la ley requiera consentimiento, se solicitará una nueva aceptación para la versión correspondiente.

AVISO PREVIO AL LANZAMIENTO: Este borrador exige revisión legal, identificación del responsable, correo de contacto, inventario definitivo de proveedores, períodos de retención y tratamiento de menores. No debe publicarse como documento legal definitivo sin completar esos datos.''';
